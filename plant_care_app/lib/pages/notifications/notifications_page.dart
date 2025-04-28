import 'package:flutter/material.dart';
import 'package:plant_care_app/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<String> _filterOptions = ['All', 'Care Reminders', 'Updates'];
  String _selectedFilter = 'All';

  bool _isLoading = true;
  List<PlantNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Convert notification_type string from database to NotificationType enum
  NotificationType _mapTypeString(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'water_reminder':
        return NotificationType.waterReminder;
      case 'fertilize_tip':
        return NotificationType.fertilizeTip;
      case 'new_plant':
        return NotificationType.newPlant;
      case 'care_tip':
      default:
        return NotificationType.careTip;
    }
  }

  // Fetch notifications from Supabase
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      print('Current user: ${user?.id}');

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch only unread notifications for the user (where is_read is false)
      print('Fetching unread notifications for user: ${user.id}');
      final response = await supabase
          .from('notifications')
          .select('''
            notification_id, 
            title, 
            description, 
            created_at, 
            notification_type, 
            plant_id, 
            is_read
          ''')
          .eq('user_id', user.id)
          .eq('is_read', false) // Only get notifications where is_read is false
          .order('created_at', ascending: false); // Newest first

      print('Response from Supabase: $response');
      print('Response length: ${response.length}');

      if (response.isEmpty) {
        print('No unread notifications found for user');
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      // Convert database records to PlantNotification objects
      final notifications =
          (response as List).map((data) {
            print(
              'Processing notification: ${data['notification_id']}, type: ${data['notification_type']}',
            );
            return PlantNotification(
              notification_id: data['notification_id'],
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              time: DateTime.parse(data['created_at']),
              type: _mapTypeString(data['notification_type']),
              plantName:
                  data['plant_id'] != null
                      ? 'Plant'
                      : null, // You may need to fetch plant name separately
              isRead: data['is_read'] ?? false,
            );
          }).toList();

      print('Processed ${notifications.length} unread notifications');

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notifications: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update notifications to set is_read = true
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      // Refresh notifications
      _fetchNotifications();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      print('Error marking notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear notifications: ${e.toString()}'),
        ),
      );
    }
  }

  List<PlantNotification> get filteredNotifications {
    if (_selectedFilter == 'All') {
      return _notifications;
    } else if (_selectedFilter == 'Care Reminders') {
      return _notifications
          .where(
            (n) =>
                n.type == NotificationType.waterReminder ||
                n.type == NotificationType.fertilizeTip,
          )
          .toList();
    } else {
      return _notifications
          .where(
            (n) =>
                n.type == NotificationType.newPlant ||
                n.type == NotificationType.careTip,
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title:  Text('Plantify', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications header and Clear All button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Filter tabs - horizontally scrollable
            SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap:
                      true, // Add this to prevent unbounded layout issues
                  children:
                      _filterOptions.map((filter) {
                        bool isSelected = filter == _selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.green
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black54,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notifications list
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                      : filteredNotifications.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        color: Colors.green,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return NotificationCard(
                              notification: notification,
                              onTap:
                                  () => {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Tapped on ${notification.title}',
                                        ),
                                      ),
                                    ),
                                  },
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final PlantNotification notification;
  final VoidCallback? onTap;

  const NotificationCard({Key? key, required this.notification, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left colored border - now uses parent height naturally
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: _getBorderColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),

                // Notification icon
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      color: _getIconColor(),
                      size: 22,
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getTitleColor(),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Time indicator
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.getFormattedTime(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Chevron icon
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get appropriate icon for notification type
  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.waterReminder:
        return Icons.water_drop;
      case NotificationType.fertilizeTip:
        return Icons.eco;
      case NotificationType.newPlant:
        return Icons.spa;
      case NotificationType.careTip:
        return Icons.access_time;
    }
  }

  // Get background color for the notification card
  Color _getBackgroundColor() {
    switch (notification.type) {
      case NotificationType.waterReminder:
        return const Color(0xFFFFF1F0);
      case NotificationType.fertilizeTip:
        return const Color(0xFFF1F8F0);
      case NotificationType.newPlant:
        return const Color(0xFFF0F5FF);
      case NotificationType.careTip:
        return const Color(0xFFF2F8F4);
    }
  }

  // Get border color for the notification
  Color _getBorderColor() {
    switch (notification.type) {
      case NotificationType.waterReminder:
        return Colors.red;
      case NotificationType.fertilizeTip:
        return Colors.green;
      case NotificationType.newPlant:
        return Colors.blue;
      case NotificationType.careTip:
        return Colors.teal;
    }
  }

  // Get title color for the notification
  Color _getTitleColor() {
    switch (notification.type) {
      case NotificationType.waterReminder:
        return Colors.red[700]!;
      case NotificationType.fertilizeTip:
        return Colors.green[700]!;
      case NotificationType.newPlant:
        return Colors.blue[700]!;
      case NotificationType.careTip:
        return Colors.teal[700]!;
    }
  }

  // Get icon color for the notification
  Color _getIconColor() {
    return Colors.white;
  }

  // Get icon background color
  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case NotificationType.waterReminder:
        return Colors.red;
      case NotificationType.fertilizeTip:
        return Colors.green;
      case NotificationType.newPlant:
        return Colors.blue;
      case NotificationType.careTip:
        return Colors.teal;
    }
  }
}
