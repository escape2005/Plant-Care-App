import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';
import 'package:plant_care_app/pages/login-signup/verify_plants.dart';
import 'package:plant_care_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_care_app/pages/login-signup/landing_page.dart';
import 'package:plant_care_app/pages/login-signup/login.dart';
import 'package:plant_care_app/pages/login-signup/sign_up.dart';
import 'package:plant_care_app/pages/login-signup/forgot_password.dart';
import 'package:plant_care_app/pages/provider/theme_provider.dart';
import 'package:plant_care_app/pages/provider/locale_provider.dart';
import 'package:provider/provider.dart';
import 'wrapper.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize providers
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();

  // Initialize notification service
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  await Supabase.initialize(
    url: 'https://xbohbkzamxgocrpyzydf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhib2hia3phbXhnb2NycHl6eWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3NDY4MDMsImV4cCI6MjA1ODMyMjgwM30.IntPbBWFhBc63lRNidOymoj3iazHGMa5lYSMNo68JRQ',
  );

  // Load saved preferences
  await Future.wait([themeProvider.loadTheme(), localeProvider.loadLocale()]);

  runApp(
    MultiProvider(
      providers: [
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
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Plantify',

          // Theme configuration
          theme: ThemeData(primarySwatch: Colors.green),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,

          // Localization configuration
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Routing configuration
          initialRoute: '/',
          routes: {
            '/':
                (context) =>
                    const AuthWrapper(), // Start with the wrapper to check authentication
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/verify': (context) => const VerifyPlants(),
            '/signup': (context) => SignUpScreen(),
            '/forgot_password': (context) => ForgotPasswordScreen(),
            '/home': (context) => BottomNavScreen(),
          },
        );
      },
    );
  }
}
