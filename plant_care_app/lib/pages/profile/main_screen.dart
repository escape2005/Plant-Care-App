import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/profile/change_password.dart';
import 'package:plant_care_app/pages/profile/contact.dart';
import 'package:plant_care_app/pages/profile/edit_profile.dart';
import 'package:plant_care_app/pages/profile/faqs.dart';
import 'package:plant_care_app/pages/profile/feedback.dart';
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
  bool _profilevisibilityEnabled = true;
  bool _activityEnabled = true;
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
              const SectionHeading(title:'Privacy'),
              _buildPrivacySection(),
              const SizedBox(height: 32),
              const SectionHeading(title:'Help & Support'),
              _buildHelpnSupporttSection(context),
              const SizedBox(height: 32),
              const SectionHeading(title: 'Additional Setting'),
              _buildadditionalsetting(context),

            ],
          ),
        ),
      ),
    );
  }

Widget _buildProfileCard() {
  return Card(
    elevation: 4,
    color: Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: const AssetImage('assets/images/plant.jpg'),
                backgroundColor: Theme.of(context).cardColor,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alka Vishwakarma',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'alkavishwakarma@example.com',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
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
        'icon': Icons.lock,
        'title': 'Change Password',
        'page': const ChangePasswordPage()
      },
      {  'icon': Icons.delete, 
         'title': 'Delete Account', 
         
         'page': null},
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
                    color: const Color.fromARGB(255, 213, 213, 213),
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


 Widget _buildPrivacySection() {
    final privacyOptions = [
      {
        'title': 'Profile Visibility',
        'subtitle': 'Control who can see your profile',
        'value': _profilevisibilityEnabled,
      },
      {
        'title': 'Activity Status',
        'subtitle': 'Show when you are active',
        'value': _activityEnabled,
      },
      
    ];

    return Column(
      children:  privacyOptions.map((option) {
        return Column(
          children: [
            _builPrivacyOption(
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              value: option['value'] as bool,
              onChanged: (value) =>
                  _handlePrivacyChange(option['title'] as String, value),
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


Widget _builPrivacyOption({
  required String title,
  required String subtitle,
  required bool value,
  required Function(bool) onChanged,
}) {
  IconData _getIcon(String title) {
    switch (title) {
      case 'Profile Visibility':
        return Icons.groups; // community/group icon
      case 'Activity Status':
        return Icons.circle_notifications; // suggestion for activity
      default:
        return Icons.privacy_tip; // fallback icon
    }
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(_getIcon(title), color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
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


   void _handlePrivacyChange(String title, bool value) {
    setState(() {
      switch (title) {
        case 'Profile Visibility':
           _profilevisibilityEnabled = value;
          break;
        case 'Activity Status':
          _activityEnabled = value;
          break;
        
      }
    });
  }

}

Widget _buildHelpnSupporttSection(BuildContext context) {
  final options = [
    {
      'icon': Icons.question_mark_outlined,
      'title': 'FAQs',
      'page': const FAQsPage()
    },
    {
      'icon': Icons.headset_mic_rounded,
      'title': 'Contact Support',
      'page': const ContactPage()
    },
    {
      'icon': Icons.telegram,
      'title': 'Send Feedback',
      'page': const SendFeedbackPage()
    },
  ];

  return Column(
    children: options.map((option) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:const Color.fromARGB(255, 213, 213, 213),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(
            option['icon'] as IconData,
            color: Theme.of(context).iconTheme.color,
            size: 28,
          ),
          title: Text(
            option['title'] as String,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
                  builder: (context) => option['page'] as Widget,
                ),
              );
            }
          },
        ),
      );
    }).toList(),
  );
}

Widget _buildadditionalsetting(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final currentLanguage = 'English'; // Replace with your language state variable
  final appVersion = '2.1.0';

  final options = [
    {
      'icon': Icons.translate,
      'title': 'Language',
      'type': 'language',
    },
    {
      'icon': Icons.dark_mode,
      'title': 'Dark Mode', 
      'type': 'theme',
    },
    {
      'icon': Icons.info_outline,
      'title': 'App Version',
      'type': 'version',
    },
  ];

  return Column(
    children: options.map((option) {
      Widget trailingWidget;
      
      switch (option['type']) {
        case 'language':
          trailingWidget = Text(
            currentLanguage,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          );
          break;
        
      case 'theme':
  trailingWidget = Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      return Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) => themeProvider.toggleTheme(value),
        activeColor: Colors.green,
        activeTrackColor: Colors.green.shade100,
      );
    },
  );

          break;
        
        case 'version':
          trailingWidget = Text(
            appVersion,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          );
          break;
        
        default:
          trailingWidget = const Icon(Icons.chevron_right);
      }

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          option['icon'] as IconData,
          color: Theme.of(context).iconTheme.color,
          size: 28,
        ),
        title: Text(
          option['title'] as String,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: trailingWidget,
        onTap: () {
          if (option['type'] == 'language') {
            // Add language selection logic
          }
        },
      );
    }).toList(),
  );
}