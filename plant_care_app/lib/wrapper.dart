import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'pages/login-signup/landing_page.dart';
// import 'pages/bottom_nav.dart';
// import 'pages/login-signup/verify_plants.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasUnverifiedPlants = false;

  @override
  void initState() {
    super.initState();
    _checkSession();

    // Listen for auth state changes
    supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      
      if (event == AuthChangeEvent.signedIn) {
        await _checkUserVerificationStatus(data.session?.user.id);
        // Force rebuild after state change
        if (mounted) {
          setState(() {});
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _hasUnverifiedPlants = false;
          });
        }
      }
    });
  }

  Future<void> _checkSession() async {
    try {
      final session = supabase.auth.currentSession;
      
      if (session != null) {
        print("User is signed in: ${session.user.id}");
        await _checkUserVerificationStatus(session.user.id);
      } else {
        print("No active session found");
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking session: $e");
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserVerificationStatus(String? userId) async {
    if (userId == null) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      return;
    }

    try {
      print("Checking verification status for user: $userId");
      final response = await supabase
          .from('adoption_record')
          .select('is_verified')
          .eq('user_id', userId);

      print("Verification response: $response");
      
      bool hasUnverifiedRecord = false;
      if (response != null && response is List && response.isNotEmpty) {
        for (var record in response) {
          if (record['is_verified'] == false) {
            hasUnverifiedRecord = true;
            print("Found unverified plant record");
            break;
          }
        }
      }

      setState(() {
        _isAuthenticated = true;
        _hasUnverifiedPlants = hasUnverifiedRecord;
        _isLoading = false;
      });
      
      print("Auth state updated: authenticated=$_isAuthenticated, hasUnverifiedPlants=$_hasUnverifiedPlants");
    } catch (e) {
      print("Error checking verification status: $e");
      setState(() {
        _isAuthenticated = true; // User is authenticated but we couldn't check plant status
        _hasUnverifiedPlants = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        ),
      );
    }

    // Defer the navigation to ensure the build method isn't interrupted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAuthenticated) {
        if (_hasUnverifiedPlants) {
          Navigator.of(context).pushReplacementNamed('/verify');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    });

    // Return a loading screen while navigation is being determined
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      ),
    );
  }
}