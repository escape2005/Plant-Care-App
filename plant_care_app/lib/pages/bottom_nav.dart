import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // for translations
import 'package:plant_care_app/pages/guides/guides_page.dart';
import 'package:plant_care_app/pages/profile/main_screen.dart';
import 'my-plants/my_plant.dart';
import 'community/community.dart';
import 'profile/profile.dart';

class BottomNavScreen extends StatefulWidget {
  final int? index;
  const BottomNavScreen({super.key, this.index});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
  }

  final List<Widget> _pages = [
    const MyPlantsScreen(),
    const GuidesPage(),
    const CommunityScreen(),
    const MainScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantify', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.local_florist), label: loc.myPlants),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book), label: loc.guides),
          BottomNavigationBarItem(icon: const Icon(Icons.group), label: loc.community),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: loc.profile),
        ],
      ),
    );
  }
}
