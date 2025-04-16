import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login-signup/landing_page.dart';
import 'pages/login-signup/verify_plants.dart';
import 'pages/bottom_nav.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _redirectUser();
  });
}


  Future<void> _redirectUser() async {
  try {
    final session = supabase.auth.currentSession;

    if (session == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/welcome');
        });
      }
      return;
    }

    final userId = session.user.id;
    final response = await supabase
        .from('adoption_record')
        .select('is_verified')
        .eq('user_id', userId);

    if (mounted) {
      setState(() => _isLoading = false);

      bool hasUnverifiedPlants = false;
      if (response != null && response is List && response.isNotEmpty) {
        for (var record in response) {
          if (record['is_verified'] == false) {
            hasUnverifiedPlants = true;
            break;
          }
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasUnverifiedPlants) {
          Navigator.of(context).pushReplacementNamed('/verify');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      });
    }
    print('Error in auth redirect: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.green)
            : Container(), // This will be replaced by navigation
      ),
    );
  }
}