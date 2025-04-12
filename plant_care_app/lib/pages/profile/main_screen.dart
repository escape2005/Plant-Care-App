import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/profile/change_password.dart';
import 'package:plant_care_app/pages/profile/edit_profile.dart';
import 'package:plant_care_app/pages/profile/section_heading.dart';
import 'package:plant_care_app/pages/provider/theme_provider.dart';
import 'package:provider/provider.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _plantCareEnabled = true;
  bool _wateringEnabled = true;
  bool _fertilizingEnabled = true;
  bool _communityUpdatesEnabled = true;
  bool _showThemeOptions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
     
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 28),
              const SectionHeading(title: 'Account'),
              _buildAccountSection(context),
              const SizedBox(height: 32),
              const SectionHeading(title: 'Notifications'),
              _buildNotificationsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      color:Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/profile.png'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alka Vishwakarma',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('alkavishwakarma@example.com',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final options = [
      {
        'icon': Icons.person,
        'title': 'Edit Profile',
        'page': const EditProfilePage()
      },
    {
      'icon': Icons.palette,
      'title': 'Theme',
      'page': null
    },
      {
        'icon': Icons.lock,
        'title': 'Change Password',
        'page': const ChangePasswordPage()
      },
      {'icon': Icons.delete, 'title': 'Delete Account', 'page': null},
    ];

    return Column(
      children: [
        ...options.map((option) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(option['icon'] as IconData, color:Theme.of(context).iconTheme.color),
                title: Text(
                  option['title'] as String,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).iconTheme.color,
                  ),
                onTap: () {
                  if (option['page'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => option['page'] as Widget),
                    );
                  }
                },
              ),
            )),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    final notificationOptions = [
      {
        'title': 'Plant care Reminders',
        'subtitle': 'Get notified about watering and care schedules',
        'value': _plantCareEnabled,
      },
      {
        'title': 'Watering schedule',
        'subtitle': 'Daily reminders for plant watering',
        'value': _wateringEnabled,
      },
      {
        'title': 'Fertilizing Alerts',
        'subtitle': 'Notifications for fertilizing schedule',
        'value': _fertilizingEnabled,
      },
      {
        'title': 'Community Updates',
        'subtitle': 'Update from plant community',
        'value': _communityUpdatesEnabled,
      },
    ];

    return Column(
      children: notificationOptions.map((option) {
        return Column(
          children: [
            _buildNotificationOption(
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              value: option['value'] as bool,
              onChanged: (value) =>
                  _handleNotificationChange(option['title'] as String, value),
            ),
            if (option['title'] != 'Community Updates')
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFE0E0E0),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.green,
                activeTrackColor: Colors.green.shade100,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationChange(String title, bool value) {
    setState(() {
      switch (title) {
        case 'Plant care Reminders':
          _plantCareEnabled = value;
          break;
        case 'Watering schedule':
          _wateringEnabled = value;
          break;
        case 'Fertilizing Alerts':
          _fertilizingEnabled = value;
          break;
        case 'Community Updates':
          _communityUpdatesEnabled = value;
          break;
      }
    });
  }
}
