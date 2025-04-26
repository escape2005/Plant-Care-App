import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/login-signup/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:flutter_markdown/flutter_markdown.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String termsContent = ""; // To store the fetched content
  bool isLoadingTerms = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchTermsAndPolicy() async {
    setState(() {
      isLoadingTerms = true;
    });

    try {
      final response =
          await Supabase.instance.client
              .from('legal_documents')
              .select('content')
              .eq('title', 'Terms and Privacy Policy')
              .single();

      setState(() {
        termsContent = response['content'] ?? "No content available.";
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Terms & Privacy Policy',
                style: TextStyle(
                  color: Colors.green[700], // Heading color green
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: MarkdownBody(
                  data: termsContent,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: TextStyle(
                      color: Colors.green[700],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    p: const TextStyle(fontSize: 14),
                    a: const TextStyle(color: Colors.blue), // links color
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load Terms. Please try again.'),
        ),
      );
    } finally {
      setState(() {
        isLoadingTerms = false;
      });
    }
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
              child: const Icon(Icons.eco, size: 80, color: Colors.green),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                "Get Started",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            // Partial clickable text
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  "By continuing, you agree to our ",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () {
                    if (!isLoadingTerms) {
                      fetchTermsAndPolicy();
                    }
                  },
                  child: const Text(
                    "Terms & Privacy Policy",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
