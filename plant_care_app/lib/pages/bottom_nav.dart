import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // for translations
import 'package:plant_care_app/pages/guides/guides_page.dart';
import 'package:plant_care_app/pages/notifications/notifications_page.dart';
import 'package:plant_care_app/pages/profile/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
    _fetchUnreadNotificationCount();
  }

  // Fetch the count of unread notifications from Supabase
  Future<void> _fetchUnreadNotificationCount() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _unreadNotificationCount = 0;
          _isLoadingNotifications = false;
        });
        return;
      }

      // Query to count notifications where is_read is false
      final response = await supabase
          .from('notifications')
          .select(
            '*',
          ) // Select all columns but we only need the count
          .eq('user_id', user.id)
          .eq('is_read', false);

      // Get the length of the response array which is our count
      final count = response.length;

      setState(() {
        _unreadNotificationCount = count;
        _isLoadingNotifications = false;
      });

      print('Unread notification count: $count');
    } catch (e) {
      print('Error fetching notification count: $e');
      setState(() {
        _unreadNotificationCount = 0;
        _isLoadingNotifications = false;
      });
    }
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // Reduced right padding to shift left
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                    // Refresh notification count when returning from notifications page
                    _fetchUnreadNotificationCount();
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_florist),
            label: loc.myPlants,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book),
            label: loc.guides,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: loc.community,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: loc.profile,
          ),
        ],
      ),
    );
  }
}
