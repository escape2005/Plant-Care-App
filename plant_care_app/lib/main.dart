// ADD THIS IMPORT FOR LOCALIZATION
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import 'package:plant_care_app/pages/provider/locale_provider.dart';
import 'wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INITIALIZE PROVIDERS
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();

  await Supabase.initialize(
    url: 'https://xbohbkzamxgocrpyzydf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhib2hia3phbXhnb2NycHl6eWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NDY4MDMsImV4cCI6MjA1ODMyMjgwM30.IntPbBWFhBc63lRNidOymoj3iazHGMa5lYSMNo68JRQ',
  );

  await Future.wait([
    themeProvider.loadTheme(),
    localeProvider.loadLocale(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        // PROVIDE EXISTING INSTANCES
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // USE Consumer2 FOR TWO PROVIDERS
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Plantify',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          
          // LOCALIZATION CONFIG
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate, // ADD THIS
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

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