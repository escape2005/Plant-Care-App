import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login-signup/landing_page.dart';
import 'pages/login-signup/login.dart';
import 'pages/login-signup/sign_up.dart';
import 'pages/login-signup/forgot_password.dart';
import 'package:plant_care_app/pages/provider/theme_provider.dart';
import 'package:provider/provider.dart';

/// Global instance of the local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xbohbkzamxgocrpyzydf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhib2hia3phbXhnb2NycHl6eWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NDY4MDMsImV4cCI6MjA1ODMyMjgwM30.IntPbBWFhBc63lRNidOymoj3iazHGMa5lYSMNo68JRQ',
  );

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  //final IOSInitializationSettings initializationSettingsIOS =
      //IOSInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    //iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Run app
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plantify',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/home': (context) => BottomNavScreen(),
      },
    );
  }
}
