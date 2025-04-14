import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();
  if (email.isEmpty || password.isEmpty) {
    _showErrorSnackbar("Please fill in all fields.");
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user != null) {
      print("User successfully logged in: ${res.user!.id}");
      
      // Check if any adoption records for this user have is_verified = false
      final response = await supabase
          .from('adoption_record')
          .select('is_verified')
          .eq('user_id', res.user!.id);
      
      print("Plant verification response: $response");
      
      // Check if any record has is_verified = false
      bool hasUnverifiedRecord = false;
      if (response != null && response is List && response.isNotEmpty) {
        for (var record in response) {
          if (record['is_verified'] == false) {
            hasUnverifiedRecord = true;
            break;
          }
        }
      }
      
      // Redirect based on verification status
      if (hasUnverifiedRecord) {
        Navigator.pushReplacementNamed(context, "/verify");
      } else {
        Navigator.pushReplacementNamed(context, "/home");
      }
    }
  } on AuthException catch (e) {
    _showErrorSnackbar(e.message);
  } catch (e) {
    _showErrorSnackbar("An unexpected error occurred.");
    print("Login error: $e"); // For debugging
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green[100],
              child: const Icon(
                Icons.eco,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Plantify",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Your Personal Plant Care Assistant",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email),
                hintText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                hintText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Log In",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
              child: const Text("Forgot Password?", style: TextStyle(color: Colors.green)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signup');
                  },
                  child: const Text("Sign Up", style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "By continuing, you agree to our Terms of Service and Privacy Policy",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}