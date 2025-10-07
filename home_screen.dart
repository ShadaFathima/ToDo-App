import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_nest/screens/login_screen.dart';
import 'package:task_nest/screens/profile_screen.dart';
import 'taskbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String nickname = "";

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _checkUsername();
  }

  void _loadNickname() async {
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = snapshot.data();
      if (data != null && data['nickname'] != null) {
        setState(() {
          nickname = data['nickname'];
        });
      }
    }
  }

  void _checkUsername() async {
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = snapshot.data();
      if (data == null || data['username'] == null || data['username'].isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please complete your profile by adding a username."),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning! 🌞";
    } else if (hour < 17) {
      return "Good Afternoon! ☀️";
    } else {
      return "Good Evening! 🌇";
    }
  }

  Color getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  bool isDueToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = nickname.isNotEmpty
        ? "Hello, $nickname..!"
        : user?.email ?? "Guest";

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0XFF4C6F56),
        elevation: 0,
        title: const Text(
          'Task Nest',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(radius: 18, backgroundColor: Color.fromARGB(255, 255, 255, 255));
                  }
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  final photoUrl = userData?['profilePic'];
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    child: photoUrl == null
                        ? const Icon(Icons.person, color: Color.fromARGB(255, 20, 20, 20))
                        : null,
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: const Color(0XFF4C6F56),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/todo.png',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
            const Text("Upcoming Tasks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0XFF4C6F56))),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('uid', isEqualTo: user?.uid)
                    .orderBy('datetime')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tasks yet. Tap + to add!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final dateTime = (data['datetime'] as Timestamp).toDate();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        color: const Color(0xFFFFFFFF),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          height: 90,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: getPriorityColor(data['priority']),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color.fromARGB(255, 245, 245, 245),
                                child: Icon(Icons.edit_note, color: Colors.orange),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF2F5942),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isDueToday(dateTime)
                                          ? 'Due Today'
                                          : DateFormat.yMMMd().add_jm().format(dateTime),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Color(0XFF4C6F56)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Task"),
                                      content: const Text("Are you sure you want to delete this task?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text("No", style: TextStyle(color: Color.fromARGB(255, 131, 9, 9))),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text("Yes", style: TextStyle(color: Color.fromARGB(255, 76, 111, 86))),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance.collection('tasks').doc(doc.id).delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: Color(0XFF4C6F56),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF4C6F56),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                color: const Color.fromARGB(255, 255, 255, 255),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person),
                color: const Color.fromARGB(255, 255, 255, 255),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
