import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Map to store all plant reminder times
  final Map<String, String> _plantReminderTimes = {};

  // Default time for reminders - 7:00 AM
  static const String defaultReminderTime = '07:00';

  NotificationService._();

  Future<void> initialize() async {
    // Initialize notification settings for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Initialize notification settings for iOS
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combine platform specific settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize plugin with settings
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Load saved reminder times
    await _loadReminderTimes();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific plant page if needed
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Request permissions for notifications
  Future<void> requestPermissions() async {
    // For Android 13+ (API level 33), we need to request permission explicitly
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  String getReminderTime(String plantName) {
    return _plantReminderTimes[plantName] ?? defaultReminderTime;
  }
  
  Future<void> _loadReminderTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reminderTimesJson = prefs.getString('plant_reminder_times');

    if (reminderTimesJson != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(reminderTimesJson);
      _plantReminderTimes.clear();
      decodedMap.forEach((key, value) {
        _plantReminderTimes[key] = value.toString();
      });
    }
  }

  // Get all saved reminder times
  Map<String, String> getAllReminderTimes() {
    return Map.from(_plantReminderTimes);
  }

  // Send an immediate test notification
  Future<void> sendTestNotification() async {
    debugPrint("Starting test notification");
    // Create notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_notification_channel',
          'Test Notifications',
          channelDescription: 'Channel for testing notifications',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.green,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Generate a random ID for this test notification
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    // Show the notification immediately
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      'Schedule Notification',
      'This is a test plant care reminder notification!',
      notificationDetails,
      payload: jsonEncode({'test': 'notification'}),
    );

    debugPrint('Test notification sent with ID: $notificationId');
  }

  Future<void> sendNotification({
    required String plantName,
    required String reminderTime,
    required int waterFrequencyDays,
  }) async {
    try {
      debugPrint("Scheduling notification for $plantName at $reminderTime");

      // Parse the reminderTime string (format: "yyyy-MM-dd HH:mm:ss")
      DateTime parsedDateTime;
      try {
        parsedDateTime = DateTime.parse(reminderTime);
        debugPrint("Successfully parsed date-time: $parsedDateTime");
      } catch (e) {
        // If parsing fails, extract time components manually
        debugPrint("Error parsing date-time: $e");

        // Split the string to extract components
        List<String> parts = reminderTime.split(' ');
        if (parts.length == 2) {
          // Get date parts
          List<String> dateParts = parts[0].split('-');
          // Get time parts
          List<String> timeParts = parts[1].split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            int year = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int day = int.parse(dateParts[2]);
            int hour = int.parse(timeParts[0]);
            int minute = int.parse(timeParts[1]);
            int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

            parsedDateTime = DateTime(year, month, day, hour, minute, second);
            debugPrint("Manually parsed date-time: $parsedDateTime");
          } else {
            throw FormatException("Invalid date-time format: $reminderTime");
          }
        } else {
          throw FormatException("Invalid date-time format: $reminderTime");
        }
      }

      // Convert to TZDateTime
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        parsedDateTime.year,
        parsedDateTime.month,
        parsedDateTime.day,
        parsedDateTime.hour,
        parsedDateTime.minute,
        parsedDateTime.second,
      );

      // Format the scheduledDate as "yyyy-MM-dd HH:mm:ss" without timezone info
      String formattedDate =
          "${scheduledDate.year}-"
          "${scheduledDate.month.toString().padLeft(2, '0')}-"
          "${scheduledDate.day.toString().padLeft(2, '0')} "
          "${scheduledDate.hour.toString().padLeft(2, '0')}:"
          "${scheduledDate.minute.toString().padLeft(2, '0')}:"
          "${scheduledDate.second.toString().padLeft(2, '0')}";

      debugPrint("Converted to TZDateTime: $formattedDate");

      // Create notification details
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'notification_channel',
            'Schedule Notifications',
            channelDescription: 'Channel for scheduling notifications',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.green,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Generate a random ID for this notification
      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Time to water your $plantName!',
        'Your plant needs water. Tap to mark as watered.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({'plantName': plantName}),
      );

      debugPrint('Scheduled notification for $plantName at $formattedDate');
    } catch (e) {
      debugPrint("Failed to schedule notification: $e");
      rethrow;
    }
  }
}
