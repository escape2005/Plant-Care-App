import 'package:flutter/material.dart';
import 'package:plant_care_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_care_app/pages/my-plants/date_time_selector.dart';
import 'plant.dart'; // Import the Plant model

DateTime selectedDate = DateTime.now();
TimeOfDay selectedTime = TimeOfDay.now();

class PlantWidgets {
  static ValueNotifier<int> refreshKey = ValueNotifier<int>(0);

  static final supabase = Supabase.instance.client;

  static Map<String, String> updatedReminderTimes = {};

  /// Builds a care information item with icon and text
  static Widget buildCareInfoItem(BuildContext context, IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds a plant category item widget
  static Widget buildPlantCategoryItem(
    BuildContext context,
    String name,
    String imagePath,
  ) {
    final bool isNetworkImage = imagePath.startsWith('http');

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  image: isNetworkImage
                      ? null
                      : DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        ),
                ),
                child: isNetworkImage
                    ? ClipOval(
                        child: Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.eco,
                                size: 30,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            );
                          },
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds a care reminder card for plants
  static Widget buildCareReminderCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required Color color,
    required Plant plant,
    VoidCallback? onUpdate, // Optional callback for updates
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Edit icon in the top right corner
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.green,
                ),
                constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                padding: const EdgeInsets.all(2),
                onPressed: () {
                  _showReminderTimeDialog(context, plant, onUpdate);
                },
                tooltip: 'Edit reminder',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showReminderTimeDialog(BuildContext context, Plant plant, VoidCallback? onUpdate) {
    // Check if there's a saved reminder time in the NotificationService
    String savedReminderTime = updatedReminderTimes[plant.speciesName] ??
        NotificationService.instance.getReminderTime(plant.speciesName);

    bool isReminderSet = savedReminderTime != NotificationService.defaultReminderTime &&
        updatedReminderTimes.containsKey(plant.speciesName);

    // Initialize with the saved reminder time or default to current time
    TimeOfDay initialTime;

    if (isReminderSet) {
      // If a reminder is already set, use that time
      final timeParts = savedReminderTime.split(' ');
      if (timeParts.length >= 2) {
        final timeComponents = timeParts[1].split(':');
        if (timeComponents.length >= 2) {
          initialTime = TimeOfDay(
            hour: int.parse(timeComponents[0]),
            minute: int.parse(timeComponents[1]),
          );
        } else {
          initialTime = TimeOfDay.now();
        }
      } else {
        initialTime = TimeOfDay.now();
      }
    } else {
      // Default to current time if no reminder is set
      initialTime = TimeOfDay.now();
    }

    Future<void> scheduleNotification() async {
      final DateTime scheduledDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Check if selected time is in the past
      if (scheduledDateTime.isBefore(DateTime.now())) {
        // Show a warning message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a time in the future.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Format time string for saving
      final formattedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      final formattedTime =
          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
      final reminderTimeString = "$formattedDate $formattedTime";

      try {
        // Save the reminder time to both the local NotificationService and the database
        await NotificationService.instance.saveReminderTime(
          plant.speciesName,
          reminderTimeString,
        );

        // Update the database if we have the adoption_id
        if (plant.adoptionId != null) {
          final supabase = Supabase.instance.client;
          final String adoptionId = plant.adoptionId!; // Create local non-nullable variable

          // Create a JSON-compatible map with non-nullable values
          final Map<String, dynamic> updateData = {};

          // Only add non-null values to the map
          if (reminderTimeString.isNotEmpty) {
            updateData['alarm_timing'] = reminderTimeString;
          }

          try {
            await supabase
                .from('adoption_record')
                .update(updateData)
                .eq('adoption_id', adoptionId); // Use local variable instead

            print('Updated alarm_timing in database for ${plant.speciesName}: $reminderTimeString');
          } catch (e) {
            print('Error updating database: $e');
            throw e; // Re-throw to be caught by the outer try-catch
          }
        } else {
          print('Cannot update database: missing adoption_id for ${plant.speciesName}');
        }

        // Update the local map for immediate UI update
        updatedReminderTimes[plant.speciesName] = reminderTimeString;
        // Increment refresh key to trigger UI update
        refreshKey.value++;
        
        // Call the update callback if provided
        if (onUpdate != null) {
          onUpdate();
        }

        // Schedule the actual notification
        await NotificationService.instance.scheduleNotification(
          plantName: plant.speciesName,
          scheduledDateTime: scheduledDateTime,
          waterFrequencyDays: plant.waterFrequencyDays ?? 15,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder set for ${plant.speciesName}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error saving reminder time: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error setting reminder: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    void updateDateTime(DateTime date, TimeOfDay time, Plant plant) {
      selectedDate = date;
      selectedTime = time;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Set Reminder Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose when to water your ${plant.speciesName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DateTimeSelector(
                    selectedDate: selectedDate,
                    selectedTime: initialTime,
                    onDateTimeChanged: (selectedDate, selectedTime) {
                      updateDateTime(selectedDate, selectedTime, plant);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    await scheduleNotification();
                    // Close the dialog immediately before async operations
                    Navigator.of(context).pop();
                  },
                  child: const Text('Set Reminder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds a plant card widget
  static Widget buildPlantCard({
    required BuildContext context,
    required String name,
    required String species,
    int daysSinceWatered = 0,
    int waterFrequencyDays = 15, // Default to 15 days if not specified
    DateTime? lastWateredDate,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    // Calculate water level and status color using logic from indi_plants.dart
    double waterLevel = 0.0;
    Color statusColor = Colors.green;
    bool isDisabled = false;
    String warningMessage = "";

    if (lastWateredDate != null) {
      final now = DateTime.now();
      final nowDate = DateTime(now.year, now.month, now.day);
      final newlastWateredDate = DateTime(
        lastWateredDate.year,
        lastWateredDate.month,
        lastWateredDate.day,
      );
      final difference = nowDate.difference(newlastWateredDate).inDays;
      daysSinceWatered = difference;

      // The maximum days (denominator) is the water frequency or default to 15
      final maxDays = waterFrequencyDays > 0 ? waterFrequencyDays : 15;

      // Calculate progress as days since last watered divided by max days
      waterLevel = difference / maxDays;

      // Check if plant needs attention (disabled state)
      if (difference > maxDays) {
        isDisabled = false;
        warningMessage =
            "Oops! You have not watered your plants for more than $maxDays days. Please share the picture of your plant with our NGO experts";
      }

      // Cap progress at 1.0 (100%)
      if (waterLevel > 1.0) {
        waterLevel = 1.0;
      }

      // Determine status color based on progress
      if (waterLevel < 0.4) {
        statusColor = Colors.green;
      } else if (waterLevel < 0.7) {
        statusColor = Colors.orange;
      } else {
        statusColor = Colors.red;
      }
    } else {
      // No watering record found
      waterLevel = 1.0;
      statusColor = Colors.red;
      isDisabled = false;
      warningMessage = "Share the first picture of your plant with the NGO experts";
    }

    return GestureDetector(
      onTap: () {
        if (isDisabled) {
          // Show warning message and scroll to photo upload section
          _showWarningAndScrollToPhotoUpload(context, warningMessage);
        } else {
          onTap();
        }
      },
      child: Opacity(
        opacity: isDisabled ? 0.7 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: isDisabled
                ? Border.all(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (isDisabled)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.onError,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDisabled ? Theme.of(context).colorScheme.error : null,
                          ),
                    ),
                    Text(
                      "Scientific Name: $species",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last watered: ${daysSinceWatered == 99999999 ? 'Never' : daysSinceWatered == 0 ? 'Today' : daysSinceWatered == 1 ? 'Yesterday' : '$daysSinceWatered days ago'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDisabled
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: isDisabled ? FontWeight.bold : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 1.0 -
                              waterLevel, // Invert the logic to show water level instead of days passed
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  waterLevel < 0.4
                                      ? Colors.green.shade700
                                      : waterLevel < 0.7
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                  waterLevel < 0.4
                                      ? Colors.green.shade400
                                      : waterLevel < 0.7
                                          ? Colors.orange.shade400
                                          : Colors.red.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showWarningAndScrollToPhotoUpload(
    BuildContext context,
    String message,
  ) {
    // Create a GlobalKey to reference the photo upload section
    // final photoUploadSectionKey = GlobalKey();

    // Show warning message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 38,
              ),
              const SizedBox(width: 10),
              // Wrap the title in Flexible to prevent overflow
              Flexible(
                child: Text(
                  'Plant Needs Attention',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Wrap content in SingleChildScrollView to handle long messages
          content: SingleChildScrollView(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Take Photo Now'),
              onPressed: () {
                Navigator.of(context).pop();

                // Delay to ensure the dialog is closed before scrolling
                Future.delayed(const Duration(milliseconds: 300), () {
                  // Find the ScrollController of the SingleChildScrollView
                  final scrollController = PrimaryScrollController.of(context);
                  // if (scrollController != null) {
                    // Scroll to the bottom where the photo upload section is
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  // }
                });
              },
            ),
          ],
        );
      },
    );
  }
}