import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();

  String? profilePicUrl;
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    print("🔄 Fetching user profile...");
    try {
      if (user == null) {
        print("⚠️ No logged-in user.");
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _usernameController.text = data['username'] ?? '';
        _nicknameController.text = data['nickname'] ?? '';
        _emailController.text = user!.email ?? '';
        profilePicUrl = data['profilePic'];
        print("✅ Profile data loaded: $data");
      } else {
        print("⚠️ No profile data found.");
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    FocusScope.of(context).unfocus();
    print("📷 Selecting image...");

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );

    if (picked == null) {
      print("❌ No image selected.");
      return;
    }

    if (user == null) {
      print("⚠️ Cannot upload: User not logged in.");
      return;
    }

    setState(() => _isLoading = true);
    final file = File(picked.path);

    try {
      print("⬆️ Uploading image to Firebase Storage...");
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('${user!.uid}.jpg');

      final uploadTask = await ref.putFile(file);
      print("✅ Image uploaded: ${uploadTask.totalBytes} bytes");

      final url = await ref.getDownloadURL();
      print("🌐 Download URL: $url");

      setState(() {
        profilePicUrl = url;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profilePic': url});
      print("✅ Firestore updated with profilePic URL.");
    } catch (e) {
      print("❌ Upload or update failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final username = _usernameController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty || nickname.isEmpty) {
      print("⚠️ Missing required fields.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username and Nickname are required")),
      );
      return;
    }

    if (user == null) {
      print("⚠️ Cannot save profile: User is null.");
      return;
    }

    setState(() => _isLoading = true);
    print("💾 Saving profile data...");

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': username,
        'nickname': nickname,
        'email': user!.email,
        'profilePic': profilePicUrl,
      });
      print("✅ Profile saved!");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      print("❌ Error saving profile: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor:Color(0xFF468558),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: profilePicUrl != null
                            ? NetworkImage(profilePicUrl!)
                            : null,
                        child: profilePicUrl == null
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save),
                  label: _isLoading
                      ? const Text("Saving...")
                      : const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 68, 122, 83),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),

                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
