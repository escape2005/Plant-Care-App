import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'plant.dart'; // Import the Plant model
import 'plant_widgets.dart';

class PlantService {
  static final supabase = Supabase.instance.client;

  /// Fetches all verified plants adopted by the current user
  static Future<List<Plant>> fetchPlants() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get adoption records with alarm_timing field and is_verified
    final response = await supabase
        .from('adoption_record')
        .select('''
        adoption_id,
        plant_id,
        alarm_timing,
        is_verified,
        plant_catalog (
          species_name,
          scientific_name,
          description,
          care_difficulty,
          days_to_water,
          sunlight_requirement,
          image_url,
          current_availability
        )
      ''')
        .eq('user_id', user.id);

    print('Fetched ${response.length} adoption records');

    // Filter to only include verified plants
    final verifiedRecords = (response as List).where((data) => data['is_verified'] == true).toList();
    
    print('After filtering, ${verifiedRecords.length} verified plants found');

    List<Plant> plants = verifiedRecords.map((data) {
      final plantData = data['plant_catalog'] as Map<String, dynamic>;

      // Debug print to see what data is coming from the database
      print(
        'Plant: ${plantData['species_name']}, adoption_id: ${data['adoption_id']}, alarm_timing: ${data['alarm_timing']}',
      );

      return Plant(
        speciesName: plantData['species_name'] ?? '',
        scientificName: plantData['scientific_name'] ?? '',
        description: plantData['description'],
        careDifficulty: plantData['care_difficulty'],
        waterFrequencyDays: int.tryParse(
          plantData['days_to_water']?.toString() ?? '0',
        ),
        sunlightRequirement: plantData['sunlight_requirement'],
        imageUrl: plantData['image_url'],
        currentAvailability: plantData['current_availability'],
        userId: user.id,
        plantId: data['plant_id'],
        adoptionId: data['adoption_id'],
        alarmTiming: data['alarm_timing'],
        isVerified: data['is_verified'] ?? false,
      );
    }).toList();

    // Fetch last watering date for each plant
    for (var plant in plants) {
      try {
        // Find the adoption_id for this plant
        final adoptionDataList = verifiedRecords
            .where(
              (data) =>
                  data['plant_catalog'] != null &&
                  data['plant_catalog']['species_name'] == plant.speciesName,
            )
            .toList();

        if (adoptionDataList.isNotEmpty) {
          final adoptionId = adoptionDataList[0]['adoption_id'];

          // Get the latest watering activity
          final wateringActivity = await supabase
              .from('daily_activity')
              .select('activity_time')
              .eq('adoption_id', adoptionId)
              .order('activity_time', ascending: false)
              .limit(1);
          
          //wateringActivity != null &&
          if ( wateringActivity.isNotEmpty) {
            plant.lastWateredDate = DateTime.parse(
              wateringActivity[0]['activity_time'],
            );
          }
        }
      } catch (e) {
        print('Error fetching watering data for ${plant.speciesName}: $e');
      }
    }

    return plants;
  }

  /// Fetches all available plants from the catalog
  static Future<List<Map<String, dynamic>>> fetchAvailablePlants() async {
    final response = await supabase
        .from('plant_catalog')
        .select('*')
        .gt('current_availability', 0);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Checks if an adoption request already exists for a specific plant
  static Future<bool> checkIfRequestExists(String plantId) async {
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      return false;
    }

    final response = await supabase
        .from('adoption_record')
        .select('adoption_id')
        .eq('user_id', user.id)
        .eq('plant_id', plantId)
        .limit(1);

    return response.isNotEmpty;
  }

  /// Picks an image from the specified source (camera or gallery)
  static Future<File?> pickImageFromSource(
    ImageSource source, {
    required BuildContext context,
  }) async {
    // Request camera permission if using camera
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera permission is required to take a photo'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return null;
      }
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    return null;
  }

  static void showAdoptionDialog(BuildContext context, Map<String, dynamic> plant) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              // Set a max height to prevent overflow
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
               child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Plant image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child:
                            plant['image_url'] != null
                                ? Image.network(
                                  plant['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surfaceVariant,
                                        child: Icon(
                                          Icons.eco,
                                          size: 60,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                )
                                : Container(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.eco,
                                    size: 60,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Plant name - Wrap in Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        plant['species_name'] ?? 'Unknown Plant',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Scientific name - Wrap in Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        plant['scientific_name'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Availability - Use Wrap instead of Row to handle overflow
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${plant['current_availability']} Available',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description - Already has maxLines and ellipsis, good!
                    if (plant['description'] != null &&
                        plant['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          plant['description'],
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Care info - Use Wrap instead of Row to handle overflow
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 12, // Horizontal space between items
                      runSpacing: 16, // Vertical space between wrapped lines
                      children: [
                        PlantWidgets.buildCareInfoItem(
                          context,
                          Icons.water_drop,
                          'Water: ${plant['days_to_water'] ?? 'N/A'} days',
                        ),
                        PlantWidgets.buildCareInfoItem(
                          context,
                          Icons.wb_sunny,
                          'Light: ${plant['sunlight_requirement'] ?? 'N/A'}',
                        ),
                        PlantWidgets.buildCareInfoItem(
                          context,
                          Icons.trending_up,
                          'Care: ${plant['care_difficulty'] ?? 'N/A'}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Adopt Now button
                    FutureBuilder<bool>(
                      // Check if the user has already requested this plant
                      future: PlantService.checkIfRequestExists(plant['plant_id']),
                      builder: (context, snapshot) {
                        // Show loading indicator while checking
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        // If request exists, show "Request Sent" button
                        if (snapshot.hasData && snapshot.data == true) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: null, // Disabled button
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Request Sent to NGO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        // If no request exists, show "Adopt Now" button
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final supabase = Supabase.instance.client;
                              final user = supabase.auth.currentUser;
                              if (user != null) {
                                try {
                                  // Add the adoption request to the table
                                  await supabase
                                      .from('adoption_requests')
                                      .insert({
                                        'plant_id': plant['plant_id'],
                                        'user_id': user.id,
                                      });

                                  // Close the dialog
                                  Navigator.pop(context);

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Adoption request sent to the NGO!',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                        ),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  // Handle errors
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error sending adoption request: ${e.toString()}',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onError,
                                        ),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  debugPrint('Error sending adoption request: $e');
                                }
                              } else {
                                // User not authenticated
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'You need to be logged in to adopt a plant',
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onError,
                                      ),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                               backgroundColor: Theme.of(context).brightness == Brightness.dark
                               ? Colors.green[800]!
                               : Colors.green[600]!,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Adopt Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String formatTimeString(String timeString) {
    if (timeString == "Not Set") {
      return timeString;
    }

    debugPrint('Formatting time string: $timeString');

    // Handle different possible formats
    // Case 1: If it has a space (like "2025-04-28 16:30")
    if (timeString.contains(' ')) {
      final timeParts = timeString.split(' ');
      if (timeParts.length >= 2) {
        final timePart = timeParts[1];
        final timeComponents = timePart.split(':');
        if (timeComponents.length >= 2) {
          final hour = int.tryParse(timeComponents[0]) ?? 0;
          final minute = int.tryParse(timeComponents[1]) ?? 0;
          final period = hour < 12 ? 'AM' : 'PM';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
        }
      }
    }
    // Case 2: If it's just a time (like "16:30")
    else if (timeString.contains(':')) {
      final timeComponents = timeString.split(':');
      if (timeComponents.length >= 2) {
        final hour = int.tryParse(timeComponents[0]) ?? 0;
        final minute = int.tryParse(timeComponents[1]) ?? 0;
        final period = hour < 12 ? 'AM' : 'PM';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
      }
    }

    // If we couldn't parse it or it's in an unexpected format, return as is
    debugPrint('Could not parse time string: $timeString');
    return timeString;
  }

  static void showPhotoSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Photo Source',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('Photo Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  PlantService.pickImageFromSource(ImageSource.gallery,context: context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  PlantService.pickImageFromSource(ImageSource.camera,context: context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
/*  static Future<void> fetchUserPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      debugPrint('Fetching user preferences, current user: ${user?.id}');

      if (user == null) {
        debugPrint('User not authenticated');
        setState(() {
          _showPlantCareReminders = false;
          _isLoadingPreferences = false;
        });
        return;
      }

      // Fetch the user's plant_care_remainder preference from user_details table
      debugPrint('Querying user_details table for plant_care_remainder');
      final response = await supabase
          .from('user_details')
          .select('plant_care_remainder')
          .eq('id', user.id)
          .limit(1);

      debugPrint('Response from user_details table: $response');

      if (response != null && response.isNotEmpty) {
        final bool showReminders =
            response[0]['plant_care_remainder'] ?? true; // Default to true
        print('plant_care_remainder value: $showReminders');
        setState(() {
          _showPlantCareReminders = showReminders;
        });
        print(
          '_showPlantCareReminders state updated to: $_showPlantCareReminders',
        );
      } else {
        debugPrint('Empty response or no user record found, defaulting to true');
        setState(() {
          _showPlantCareReminders = true; // Default to true if no record exists
        });
      }
    } catch (e) {
      debugPrint('Error fetching user preferences: $e');
      // Default to true if there was an error
      setState(() {
        _showPlantCareReminders = true;
      });
    } finally {
      setState(() {
        _isLoadingPreferences = false;
      });
    }
  }
*/
}