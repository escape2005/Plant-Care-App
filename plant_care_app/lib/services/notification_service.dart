import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Map to store all plant reminder times
  final Map<String, String> _plantReminderTimes = {};

  // Default time for reminders - 7:00 AM
  static const String defaultReminderTime = '07:00';

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
          importance: Importance.max,
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
      'Instant Notification',
      'This is a test plant care reminder notification!',
      notificationDetails,
      payload: jsonEncode({'test': 'notification'}),
    );

    debugPrint('Test notification sent with ID: $notificationId');
  }



  Future<void> scheduleNotification({
    required String plantName,
    required DateTime scheduledDateTime,
    required int waterFrequencyDays,
  }) async {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'notification_channel',
            'Schedule Notifications',
            channelDescription: 'Channel for scheduling notifications',
            importance: Importance.max,
            priority: Priority.high,
            color: Colors.green,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails
      );

      // Generate a random ID for this notification
      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Water your $plantName!',
        'Your plant needs water. Tap to mark as watered.',
        tz.TZDateTime.from(scheduledDateTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({'plantName': plantName}),
      );

      debugPrint('Scheduled notification for $plantName at $scheduledDateTime');
    } 
}
