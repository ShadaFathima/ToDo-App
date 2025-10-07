import 'package:flutter/material.dart';
import 'main_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome To',
                style: TextStyle(fontSize: 24, color: Color(0xFF468558)),
              ),
              const Text(
                'Task Nest ...!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF468558)),
              ),
              const SizedBox(height: 40),
              Image.asset('assets/images/rocket.png', height: 200), // Use your image
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 37, 73, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Get Started!", style: TextStyle(fontSize: 18 ,color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
