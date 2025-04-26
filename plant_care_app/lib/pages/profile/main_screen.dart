import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/profile/Delete_Account.dart';
import 'package:plant_care_app/pages/profile/change_password.dart';
import 'package:plant_care_app/pages/profile/contact.dart';
import 'package:plant_care_app/pages/profile/edit_profile.dart';
import 'package:plant_care_app/pages/profile/faqs.dart';
import 'package:plant_care_app/pages/profile/feedback.dart';
import 'package:plant_care_app/pages/profile/section_heading.dart';
import 'package:plant_care_app/pages/provider/locale_provider.dart';
import 'package:plant_care_app/pages/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Keep all existing state variables
  bool _plantCareEnabled = true;
  bool _wateringEnabled = true;
  bool _fertilizingEnabled = true;
  bool _communityUpdatesEnabled = true;
  bool _profilevisibilityEnabled = true;
  bool _activityEnabled = true;
  bool _showThemeOptions = false;

  // Add these new variables
  String _userEmail = '';
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Add this initialization
  }

  // Add this new method
  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response =
            await Supabase.instance.client
                .from('user_details')
                .select()
                .eq('id', user.id)
                .single();

        setState(() {
          _userEmail = response['user_email'] ?? '';
          _userName = response['user_name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileCard(),
              // Keep all existing widgets below exactly as they were
              const SizedBox(height: 28),
              SectionHeading(
                title: Text(AppLocalizations.of(context)!.account),
              ),
              _buildAccountSection(context),
              const SizedBox(height: 32),
              SectionHeading(
                title: Text(AppLocalizations.of(context)!.notifications),
              ),
              _buildNotificationsSection(),
              const SizedBox(height: 32),
              // SectionHeading(
              //   title: Text(AppLocalizations.of(context)!.privacy),
              // ),
              // _buildPrivacySection(),
              // const SizedBox(height: 32),
              SectionHeading(
                title: Text(AppLocalizations.of(context)!.helpSupport),
              ),
              _buildHelpnSupporttSection(context),
              const SizedBox(height: 32),
              SectionHeading(
                title: Text(AppLocalizations.of(context)!.additionalSettings),
              ),
              _buildadditionalsetting(context),
            ],
          ),
        ),
      ),
    );
  }

  // Modified profile card widget
  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      // Modified line
                      _isLoading
                          ? AppLocalizations.of(context)!.profileName
                          : (_userName.isNotEmpty
                              ? _userName
                              : AppLocalizations.of(context)!.profileName),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Modified line
                      _isLoading
                          ? AppLocalizations.of(context)!.profileEmail
                          : (_userEmail.isNotEmpty
                              ? _userEmail
                              : AppLocalizations.of(context)!.profileEmail),
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

  // Keep all your existing methods exactly as they were:
  // _buildAccountSection, _buildNotificationsSection,
  // _buildPrivacySection, _buildHelpnSupporttSection,
  // _buildadditionalsetting, etc.

  Widget _buildAccountSection(BuildContext context) {
    final options = [
      {
        'icon': Icons.person,
        'title': AppLocalizations.of(context)!.editProfile,
        'page': const EditProfilePage(),
      },
      {
        'icon': Icons.lock,
        'title': AppLocalizations.of(context)!.changePassword,
        'page': const ChangePasswordPage(),
      },
      {
        'icon': Icons.delete,
        'title': AppLocalizations.of(context)!.deleteAccount,
        'page': const DeletePage(),
      },
    ];

    return Column(
      children: [
        ...options.map(
          (option) => Container(
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
              leading: Icon(
                option['icon'] as IconData,
                color: Theme.of(context).iconTheme.color,
              ),
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
                      builder: (context) => option['page'] as Widget,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    final notificationOptions = [
      {
        'key': 'plantCareReminders',
        'title': AppLocalizations.of(context)!.plantCareReminders,
        'subtitle': AppLocalizations.of(context)!.careReminderDesc,
        'value': _plantCareEnabled,
      },
      // {
      //   'key': 'wateringSchedule',
      //   'title': AppLocalizations.of(context)!.wateringSchedule,
      //   'subtitle': AppLocalizations.of(context)!.wateringDesc,
      //   'value': _wateringEnabled,
      // },
      // {
      //   'key': 'fertilizingAlerts',
      //   'title': AppLocalizations.of(context)!.fertilizingAlerts,
      //   'subtitle': AppLocalizations.of(context)!.fertilizingDesc,
      //   'value': _fertilizingEnabled,
      // },
      // {
      //   'key': 'communityUpdates',
      //   'title': AppLocalizations.of(context)!.communityUpdates,
      //   'subtitle': AppLocalizations.of(context)!.communityDesc,
      //   'value': _communityUpdatesEnabled,
      // },
    ];

    return Column(
      children:
          notificationOptions.map((option) {
            return Column(
              children: [
                _buildNotificationOption(
                  title: option['title'] as String,
                  subtitle: option['subtitle'] as String,
                  value: option['value'] as bool,
                  onChanged:
                      (value) => _handleNotificationChange(
                        option['title'] as String,
                        value,
                      ),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationChange(String title, bool value) {
    setState(() {
      // Using a mapping approach instead of switch case with incorrect Key variable
      if (title == AppLocalizations.of(context)!.plantCareReminders) {
        _plantCareEnabled = value;
      } else if (title == AppLocalizations.of(context)!.wateringSchedule) {
        _wateringEnabled = value;
      } else if (title == AppLocalizations.of(context)!.fertilizingAlerts) {
        _fertilizingEnabled = value;
      } else if (title == AppLocalizations.of(context)!.communityUpdates) {
        _communityUpdatesEnabled = value;
      }
    });
  }

  Widget _buildPrivacySection() {
    final privacyOptions = [
      {
        'key': 'profileVisibility',
        'title': AppLocalizations.of(context)!.profileVisibility,
        'subtitle': AppLocalizations.of(context)!.visibilitySubtitle,
        'value': _profilevisibilityEnabled,
      },
      {
        'key': 'activityStatus',
        'title': AppLocalizations.of(context)!.activityStatus,
        'subtitle': AppLocalizations.of(context)!.activitySubtitle,
        'value': _activityEnabled,
      },
    ];

    return Column(
      children:
          privacyOptions.map((option) {
            return Column(
              children: [
                _builPrivacyOption(
                  title: option['title'] as String,
                  subtitle: option['subtitle'] as String,
                  value: option['value'] as bool,
                  onChanged:
                      (value) => _handlePrivacyChange(
                        option['title'] as String,
                        value,
                      ),
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
      if (title == AppLocalizations.of(context)!.profileVisibility) {
        return Icons.groups; // community/group icon
      } else if (title == AppLocalizations.of(context)!.activityStatus) {
        return Icons.circle_notifications; // for activity status
      } else {
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrivacyChange(String title, bool value) {
    setState(() {
      // Using consistent approach with notification toggles
      if (title == AppLocalizations.of(context)!.profileVisibility) {
        _profilevisibilityEnabled = value;
      } else if (title == AppLocalizations.of(context)!.activityStatus) {
        _activityEnabled = value;
      }
    });
  }
}

Widget _buildHelpnSupporttSection(BuildContext context) {
  final options = [
    {
      'icon': Icons.question_mark_outlined,
      'title': AppLocalizations.of(context)!.faqs,
      'page': const FAQsPage(),
    },
    {
      'icon': Icons.headset_mic_rounded,
      'title': AppLocalizations.of(context)!.contactSupport,
      'page': const ContactScreen(),
    },
    {
      'icon': Icons.telegram,
      'title': AppLocalizations.of(context)!.sendFeedback,
      'page': const FeedbackPage(),
    },
  ];

  return Column(
    children:
        options.map((option) {
          return Container(
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
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
  // Changed from ThemeProvider to include LocaleProvider
  final themeProvider = Provider.of<ThemeProvider>(context);
  final localeProvider = Provider.of<LocaleProvider>(
    context,
  ); // Added locale provider

  // Changed from hardcoded 'English' to dynamic localization
  final appVersion = '2.1.0';

  // Updated options to use localized strings
  final options = [
    {
      'icon': Icons.translate,
      'title': AppLocalizations.of(context)!.language, // Localized title
      'type': 'language',
    },
    {
      'icon': Icons.dark_mode,
      'title': AppLocalizations.of(context)!.darkMode, // Localized title
      'type': 'theme',
    },
    {
      'icon': Icons.info_outline,
      'title': AppLocalizations.of(context)!.appVersion, // Localized title
      'type': 'version',
    },
  ];

  return Column(
    children:
        options.map((option) {
          Widget trailingWidget;

          switch (option['type']) {
            case 'language':
              // Updated to show localized language name
              trailingWidget = Text(
                _getCurrentLanguageName(context, localeProvider.locale),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
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
                // Added language selection dialog
                _showLanguageDialog(context, localeProvider);
              }
            },
          );
        }).toList(),
  );
}

// New helper function to get localized language name
String _getCurrentLanguageName(BuildContext context, Locale? locale) {
  switch (locale?.languageCode) {
    case 'hi':
      return AppLocalizations.of(context)!.hindi;
    case 'mr':
      return AppLocalizations.of(context)!.marathi;
    default:
      return AppLocalizations.of(context)!.english;
  }
}

// New function to show language selection dialog
void _showLanguageDialog(BuildContext context, LocaleProvider provider) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.chooseLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.english),
                onTap: () {
                  provider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.hindi),
                onTap: () {
                  provider.setLocale(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.marathi),
                onTap: () {
                  provider.setLocale(const Locale('mr'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
  );
}
