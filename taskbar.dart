import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart'; // Make sure to import your main file for the global notification plugin

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _priority = 'Medium';
  String _alarmOption = '5 minutes before';
  bool _isLoading = false;
  String? _error;

  final _alarmOptions = [
    'At time of event',
    '5 minutes before',
    '10 minutes before',
    '30 minutes before',
    '1 hour before',
    '1 day before'
  ];

  Duration _getOffset() {
    switch (_alarmOption) {
      case '5 minutes before':
        return const Duration(minutes: -5);
      case '10 minutes before':
        return const Duration(minutes: -10);
      case '30 minutes before':
        return const Duration(minutes: -30);
      case '1 hour before':
        return const Duration(hours: -1);
      case '1 day before':
        return const Duration(days: -1);
      default:
        return Duration.zero;
    }
  }

  Future<void> _scheduleNotification(String title, DateTime reminderTime) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Task Reminder',
      title,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Reminds about your tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDate == null || _selectedTime == null) {
      setState(() => _error = "All fields are required");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fullDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final reminderTime = fullDateTime.add(_getOffset());

      await FirebaseFirestore.instance.collection('tasks').add({
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'title': title,
        'datetime': fullDateTime,
        'priority': _priority,
        'alarmTime': reminderTime,
        'createdAt': Timestamp.now(),
      });

      await _scheduleNotification(title, reminderTime);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = "Failed to add task: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text("Add Task"),
        backgroundColor: const Color(0xFF4C6F56),
        foregroundColor: Color(0xFFFFFFFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                labelStyle: TextStyle(color: Color(0xFF4C6F56)),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4C6F56)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4C6F56), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6F56),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _selectedDate == null
                          ? "Pick Date"
                          : DateFormat.yMMMd().format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6F56),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _selectedTime == null
                          ? "Pick Time"
                          : _selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                labelStyle: TextStyle(color: Color(0xFF4C6F56)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4C6F56)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4C6F56), width: 2),
                ),
              ),
              style: const TextStyle(color: Color(0xFF4C6F56)),
              items: const [
                DropdownMenuItem(value: 'High', child: Text('High Priority')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium Priority')),
                DropdownMenuItem(value: 'Low', child: Text('Low Priority')),
              ],
              onChanged: (val) => setState(() => _priority = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _alarmOption,
              decoration: const InputDecoration(
                labelText: 'Alarm Time',
                labelStyle: TextStyle(color: Color(0xFF4C6F56)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4C6F56)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4C6F56), width: 2),
                ),
              ),
              style: const TextStyle(color: Color(0xFF4C6F56)),
              items: _alarmOptions
                  .map((opt) =>
                      DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) => setState(() => _alarmOption = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addTask,
              icon: const Icon(Icons.add),
              label: _isLoading
                  ? const Text("Adding...")
                  : const Text("Add Task"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C6F56),
                foregroundColor: Colors.white,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
