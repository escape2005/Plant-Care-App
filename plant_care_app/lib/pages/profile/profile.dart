// import 'package:flutter/material.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text("Profile Page"),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:plant_care_app/pages/profile/main_screen.dart';


// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Plantify',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         scaffoldBackgroundColor: Colors.grey[100],
//       ),
//       home: const MainScreen(),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/profile/main_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plantify',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainScreen(), // Replaced MainScreen with ProfileScreen
    );
  }
}


