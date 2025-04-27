import 'package:flutter/material.dart';

enum NotificationType { waterReminder, fertilizeTip, newPlant, careTip }

class PlantNotification {
  final String notification_id;
  final String title;
  final String description;
  final DateTime time;
  final NotificationType type;
  final String? plantName;
  final bool isRead;

  PlantNotification({
    required this.notification_id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.plantName,
    this.isRead = false,
  });

  // Get the appropriate icon for the notification type
  IconData get icon {
    switch (type) {
      case NotificationType.waterReminder:
        return Icons.water_drop; // Water drop icon for watering reminders
      case NotificationType.fertilizeTip:
        return Icons.eco; // Leaf icon for fertilizing tips
      case NotificationType.newPlant:
        return Icons.spa; // Flower icon for new plants
      case NotificationType.careTip:
        return Icons.access_time; // Clock icon for care tips
    }
  }

  // Get the color for the notification type
  Color get color {
    switch (type) {
      case NotificationType.waterReminder:
        return Colors.red; // Red for watering reminders
      case NotificationType.fertilizeTip:
        return Colors.green; // Green for fertilizing tips
      case NotificationType.newPlant:
        return Colors.blue; // Blue for new plants
      case NotificationType.careTip:
        return Colors.teal; // Teal for care tips
    }
  }

  // Format the time relative to now (e.g., "10 minutes ago", "Yesterday")
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
