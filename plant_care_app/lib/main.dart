import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';
import 'package:plant_care_app/pages/login-signup/verify_plants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_care_app/pages/login-signup/landing_page.dart';
import 'package:plant_care_app/pages/login-signup/login.dart';
import 'package:plant_care_app/pages/login-signup/sign_up.dart';
import 'package:plant_care_app/pages/login-signup/forgot_password.dart';
import 'package:plant_care_app/pages/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xbohbkzamxgocrpyzydf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhib2hia3phbXhnb2NycHl6eWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NDY4MDMsImV4cCI6MjA1ODMyMjgwM30.IntPbBWFhBc63lRNidOymoj3iazHGMa5lYSMNo68JRQ',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Plantify',
          theme: ThemeData.light(), // Default light theme
          darkTheme: ThemeData.dark(), // Default dark theme
          themeMode: themeProvider.themeMode,
          initialRoute: '/welcome',
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => SignUpScreen(),
            '/forgot_password': (context) => ForgotPasswordScreen(),
            '/home': (context) => BottomNavScreen(),
            
          },
        );
      },
    );
  }
}


