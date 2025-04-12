import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/invite-login/invite_login.dart';
import 'login.dart';

// Assuming this is accessible globally (as in main.dart)

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.green[100],
              child: const Icon(
                Icons.eco,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Plantify",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your personal plant care companion",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            const Text(
              "Join our community of plant lovers and learn how to keep your plants healthy and thriving",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InviteLoginPage()),
                );
              },
              child: const Text(
                "Get Started",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "By continuing, you agree to our Terms & Privacy Policy",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
