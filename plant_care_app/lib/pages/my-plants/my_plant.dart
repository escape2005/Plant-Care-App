// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';
import 'package:plant_care_app/pages/indi-plants/indi_plants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'adopt_plant.dart';

final bottomNav = const BottomNavScreen();

class Plant {
  final String speciesName;
  final String scientificName;
  final String? description;
  final String? careDifficulty;
  final int? waterFrequencyDays;
  final String? sunlightRequirement;
  final String? imageUrl;
  final int? currentAvailability;
  final String userId;
  DateTime?
  lastWateredDate; // Added field to track when the plant was last watered
  final String? timeToWater; // Add this field to store time_to_water

  Plant({
    required this.speciesName,
    required this.scientificName,
    this.description,
    this.careDifficulty,
    this.waterFrequencyDays,
    this.sunlightRequirement,
    this.imageUrl,
    this.currentAvailability,
    required this.userId,
    this.lastWateredDate,
    this.timeToWater,
  });

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      speciesName: map['species_name'] ?? '',
      scientificName: map['scientific_name'] ?? '',
      description: map['description'],
      careDifficulty: map['care_difficulty'],
      waterFrequencyDays: int.tryParse(map['days_to_water']?.toString() ?? '0'),
      sunlightRequirement: map['sunlight_requirement'],
      imageUrl: map['image_url'],
      currentAvailability: map['current_availability'],
      userId: map['user_id'] ?? '',
      timeToWater: map['time_to_water'],
    );
  }
}

Future<List<Plant>> fetchPlants() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('User not authenticated');
  }

  final response = await supabase
      .from('adoption_record')
      .select('''
      adoption_id,
      plant_id,
      plant_catalog (
        species_name,
        scientific_name,
        description,
        care_difficulty,
        days_to_water,
        sunlight_requirement,
        image_url,
        current_availability,
        time_to_water
      )
    ''')
      .eq('user_id', user.id);

  List<Plant> plants =
      (response as List).map((data) {
        final plantData = data['plant_catalog'] as Map<String, dynamic>;
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
          timeToWater: plantData['time_to_water'], // Add this line
        );
      }).toList();

  // Fetch last watering date for each plant
  for (var plant in plants) {
    try {
      // Find the adoption_id for this plant - FIX HERE
      final adoptionDataList =
          (response as List)
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

        if (wateringActivity != null && wateringActivity.isNotEmpty) {
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

Future<List<Map<String, dynamic>>> fetchPlantCategories() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Fetch all plants for the user
  final response = await supabase
      .from('adoption_record')
      .select('''
        plant_id,
        plant_catalog (
          species_name,
          image_url
        )
      ''')
      .eq('user_id', user.id);

  // Extract unique species from the response
  final Map<String, Map<String, dynamic>> uniqueSpecies = {};

  for (var data in response as List) {
    final plantData = data['plant_catalog'] as Map<String, dynamic>;
    final speciesName = plantData['species_name'] as String? ?? '';

    if (speciesName.isNotEmpty && !uniqueSpecies.containsKey(speciesName)) {
      uniqueSpecies[speciesName] = {
        'species_name': speciesName,
        'image_url': plantData['image_url'],
      };
    }
  }

  return uniqueSpecies.values.toList();
}

Future<List<Map<String, dynamic>>> fetchAvailablePlants() async {
  final supabase = Supabase.instance.client;

  // Fetch all plants with availability > 0
  final response = await supabase
      .from('plant_catalog')
      .select('*')
      .gt('current_availability', 0);

  if (response is List) {
    return response.map((data) => data as Map<String, dynamic>).toList();
  }

  return [];
}

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Section - Horizontal Plant Category Circles
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAvailablePlants(),
              builder: (context, snapshot) {
                final theme = Theme.of(context);
                final textColor =
                    theme.textTheme.bodyMedium?.color ?? Colors.black;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading plants: ${snapshot.error}',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No plants available for adoption',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  );
                } else {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final plant = snapshot.data![index];
                      final speciesName =
                          plant['species_name'] as String? ?? 'Unknown';
                      final imageUrl = plant['image_url'] as String?;

                      return GestureDetector(
                        onTap: () {
                          // Show adoption dialog when plant is tapped
                          _showAdoptionDialog(context, plant);
                        },
                        child: _buildPlantCategoryItem(
                          context,
                          speciesName,
                          imageUrl ?? 'assets/images/plant.jpg',
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          // Third Section - Today's Plant Care
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Plant Care",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 125,
                  child: FutureBuilder<List<Plant>>(
                    future: fetchPlants(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading plant care reminders: ${snapshot.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No plants to water today',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        );
                      } else {
                        // Filter plants that need watering today
                        // A plant needs watering today if:
                        // 1. It has never been watered (lastWateredDate is null), or
                        // 2. Days since last watered >= water frequency days
                        final today = DateTime.now();
                        final plantsToWater =
                            snapshot.data!.where((plant) {
                              if (plant.lastWateredDate == null) return true;

                              final daysSinceWatered =
                                  today
                                      .difference(plant.lastWateredDate!)
                                      .inDays;
                              final waterFrequency =
                                  plant.waterFrequencyDays ?? 15;
                              return daysSinceWatered >= waterFrequency;
                            }).toList();

                        if (plantsToWater.isEmpty) {
                          return Center(
                            child: Text(
                              'All plants are watered for today!',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: plantsToWater.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final plant = plantsToWater[index];
                            // Format time_to_water for display
                            // Note: time_to_water is expected to be a string in format like "10:00:00"
                            String displayTime = "Anytime";
                            if (plant.timeToWater != null &&
                                plant.timeToWater!.isNotEmpty) {
                              // Parse time from time_to_water (expected format "10:00:00")
                              final timeParts = plant.timeToWater!.split(':');
                              if (timeParts.length >= 2) {
                                final hour = int.tryParse(timeParts[0]) ?? 0;
                                final minute = int.tryParse(timeParts[1]) ?? 0;
                                final period = hour < 12 ? 'AM' : 'PM';
                                final displayHour =
                                    hour % 12 == 0 ? 12 : hour % 12;
                                displayTime =
                                    '$displayHour:${minute.toString().padLeft(2, '0')} $period';
                              }
                            }

                            return _buildCareReminderCard(
                              context: context,
                              icon:
                                  Icons
                                      .water_drop, // Only use water icon as requested
                              title: 'Water ${plant.speciesName}',
                              time: displayTime,
                              color: Theme.of(context).colorScheme.primary,
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fourth Section - All Plants
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Plants",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Plant>>(
                  future: fetchPlants(),
                  builder: (context, snapshot) {
                    // Calculate stats based on plant data
                    int totalPlants = 0;
                    int healthyPlants = 0;
                    int needsCare = 0;

                    if (snapshot.hasData) {
                      totalPlants = snapshot.data!.length;

                      for (var plant in snapshot.data!) {
                        // Calculate water level using the same logic as in _buildPlantCard
                        double waterLevel = 0.0;

                        if (plant.lastWateredDate != null) {
                          final now = DateTime.now();
                          final difference =
                              now.difference(plant.lastWateredDate!).inDays;
                          final maxDays =
                              plant.waterFrequencyDays! > 0
                                  ? plant.waterFrequencyDays!
                                  : 15;

                          waterLevel = difference / maxDays;
                          if (waterLevel > 1.0) waterLevel = 1.0;
                        } else {
                          waterLevel = 1.0; // No watering record found
                        }

                        // Count healthy vs needs care plants
                        if (waterLevel < 0.7) {
                          healthyPlants++;
                        } else {
                          needsCare++;
                        }
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Total Plants
                          Expanded(
                            child: Container(
                              height: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor,
                                    spreadRadius: 0.1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalPlants',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total Plants',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Healthy
                          Expanded(
                            child: Container(
                              height: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor,
                                    spreadRadius: 0.1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$healthyPlants',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Healthy',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Needs Care
                          Expanded(
                            child: Container(
                              height: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor,
                                    spreadRadius: 0.1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.healing,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$needsCare',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Needs Care',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer
                                          .withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FutureBuilder<List<Plant>>(
                  future: fetchPlants(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 16,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_florist_outlined,
                              size: 64,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No plants allocated yet',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kindly contact the NGO for assistance',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children:
                            snapshot.data!.map((plant) {
                              // Calculate days since watered
                              int daysSinceWatered = 0;
                              if (plant.lastWateredDate != null) {
                                daysSinceWatered =
                                    DateTime.now()
                                        .difference(plant.lastWateredDate!)
                                        .inDays;
                              } else {
                                daysSinceWatered =
                                    99999999; // Default to 0 if no date
                              }

                              return Column(
                                children: [
                                  _buildPlantCard(
                                    context: context,
                                    name: plant.speciesName,
                                    species: plant.scientificName,
                                    daysSinceWatered: daysSinceWatered,
                                    waterFrequencyDays:
                                        plant.waterFrequencyDays ?? 15,
                                    lastWateredDate: plant.lastWateredDate,
                                    imagePath:
                                        plant.imageUrl ??
                                        'assets/images/plant.jpg',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => IndiPlants(
                                                speciesName: plant.speciesName,
                                                scientificName:
                                                    plant.scientificName,
                                                imageUrl: plant.imageUrl,
                                                waterFrequencyDays:
                                                    plant.waterFrequencyDays ??
                                                    15,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Fifth Section - Add Plant Photo
          Padding(
            padding: const EdgeInsets.all(16),
            key: GlobalKey(debugLabel: 'photoUploadSection'), // Add this key
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add your plant photo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your plant with our NGO experts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // BACKEND: Handle photo upload
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Select Photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningAndScrollToPhotoUpload(
    BuildContext context,
    String message,
  ) {
    // Create a GlobalKey to reference the photo upload section
    final photoUploadSectionKey = GlobalKey();

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
                  if (scrollController != null) {
                    // Scroll to the bottom where the photo upload section is
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showAdoptionDialog(BuildContext context, Map<String, dynamic> plant) {
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
                        _buildCareInfoItem(
                          context,
                          Icons.water_drop,
                          'Water: ${plant['days_to_water'] ?? 'N/A'} days',
                        ),
                        _buildCareInfoItem(
                          context,
                          Icons.wb_sunny,
                          'Light: ${plant['sunlight_requirement'] ?? 'N/A'}',
                        ),
                        _buildCareInfoItem(
                          context,
                          Icons.trending_up,
                          'Care: ${plant['care_difficulty'] ?? 'N/A'}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Adopt Now button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle the adoption process - left empty for now as requested
                          // adoptPlant(plant['id']);
                          Navigator.pop(context);

                          // You might want to navigate to adopt_plant.dart here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdoptPlant(plant: plant),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
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

  Widget _buildCareInfoItem(BuildContext context, IconData icon, String text) {
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

  Widget _buildPlantCategoryItem(
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
                  image:
                      isNetworkImage
                          ? null
                          : DecorationImage(
                            image: AssetImage(imagePath),
                            fit: BoxFit.cover,
                          ),
                ),
                child:
                    isNetworkImage
                        ? ClipOval(
                          child: Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.eco,
                                  size: 30,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCareReminderCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildPlantCard({
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
      final difference = now.difference(lastWateredDate).inDays;

      // The maximum days (denominator) is the water frequency or default to 15
      final maxDays = waterFrequencyDays > 0 ? waterFrequencyDays : 15;

      // Calculate progress as days since last watered divided by max days
      waterLevel = difference / maxDays;

      // Check if plant needs attention (disabled state)
      if (difference > maxDays) {
        isDisabled = true;
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
      isDisabled = true;
      warningMessage =
          "Share the first picture of your plant with the NGO experts";
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
            border:
                isDisabled
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
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                        color:
                            isDisabled
                                ? Theme.of(context).colorScheme.error
                                : null,
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
                      'Last watered: ${daysSinceWatered == 99999999
                          ? 'Never'
                          : daysSinceWatered == 0
                          ? 'Today'
                          : daysSinceWatered == 1
                          ? 'Yesterday'
                          : '$daysSinceWatered days ago'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            isDisabled
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                        fontWeight: isDisabled ? FontWeight.bold : null,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor:
                              1.0 -
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
}
