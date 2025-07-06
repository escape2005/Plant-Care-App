
import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/indi-plants/indi_plants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//FILE SEPARATION IMPORTS
import 'plant.dart';
import 'plant_service.dart';
import 'plant_widgets.dart';


class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  MyPlantsScreenState createState() => MyPlantsScreenState();
}

class MyPlantsScreenState extends State<MyPlantsScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // Map to store updated reminder times for plants
  final Map<String, String> _updatedReminderTimes = {};

  // Flag to control visibility of the plant care reminder section
  bool _showPlantCareReminders = false;
  bool isLoadingPreferences = true;

  // Add a refresh key to force UI updates when reminder times change
  final ValueNotifier<int> _refreshKey = ValueNotifier<int>(0);

  @override
  bool get wantKeepAlive => true; // Keep this widget alive when switching tabs

  @override
  void initState() {
    super.initState();
    // Add observer to detect when the app comes back to foreground
    WidgetsBinding.instance.addObserver(this);
    _fetchUserPreferences();
  }

  @override
  void dispose() {
    // Remove the observer when disposing
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background, refresh preferences
    if (state == AppLifecycleState.resumed) {
      _fetchUserPreferences();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh preferences when returning to this screen
    _fetchUserPreferences();
  }

  // Public method to refresh the state when tab is selected
  void refreshState() {
    if (mounted) {
      _fetchUserPreferences();
      // Increment refresh key to trigger UI update of plant care reminders
      _refreshKey.value++;
      debugPrint('MyPlantsScreen state refreshed via public method');
    }
  }

  // Fetch user preferences from Supabase
  Future<void> _fetchUserPreferences() async {
    setState(() {
      isLoadingPreferences = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      debugPrint('Fetching user preferences, current user: ${user?.id}');

      if (user == null) {
        debugPrint('User not authenticated');
        setState(() {
          _showPlantCareReminders = false;
          isLoadingPreferences = false;
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

      //response != null && 
      if (response.isNotEmpty) {
        final bool showReminders =
            response[0]['plant_care_remainder'] ?? true; // Default to true
        debugPrint('plant_care_remainder value: $showReminders');
        setState(() {
          _showPlantCareReminders = showReminders;
        });
        debugPrint(
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
        isLoadingPreferences = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // final ScrollController scrollController = ScrollController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Section - Horizontal Plant Category Circles
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: PlantService.fetchAvailablePlants(),
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
                        color: textColor.withAlpha((0.6 * 255).round()),
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
                          PlantService.showAdoptionDialog(context, plant);
                        },
                        child: PlantWidgets.buildPlantCategoryItem(
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

          // Third Section - Today's Plant Care (conditionally shown)
          if (_showPlantCareReminders) // Only show this section if plant_care_remainder is true
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Plant Care",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ValueListenableBuilder(
                      valueListenable: _refreshKey,
                      builder: (context, _, __) {
                        return FutureBuilder<List<Plant>>(
                          future: PlantService.fetchPlants(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  'No plants to care for today',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }

                            // Display all plants, regardless of watering status
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: snapshot.data!.length,
                              separatorBuilder:
                                  (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final plant = snapshot.data![index];

                                // Check if plant needs watering
                                final today = DateTime.now();
                                bool needsWatering = true;
                                if (plant.lastWateredDate != null) {
                                  final daysSinceWatered =
                                      today
                                          .difference(plant.lastWateredDate!)
                                          .inDays;
                                  final waterFrequency =
                                      plant.waterFrequencyDays ?? 15;
                                  needsWatering =
                                      daysSinceWatered >= waterFrequency;
                                }

                                // Get reminder time from database or local updates
                                String reminderTime = "Not Set";
                                if (_updatedReminderTimes.containsKey(
                                  plant.speciesName,
                                )) {
                                  // If there's a pending update, use that
                                  print(
                                    'Using updated reminder time for ${plant.speciesName}: ${_updatedReminderTimes[plant.speciesName]}',
                                  );
                                  reminderTime = PlantService.formatTimeString(
                                    _updatedReminderTimes[plant.speciesName]!,
                                  );
                                } else if (plant.alarmTiming != null &&
                                    plant.alarmTiming!.isNotEmpty) {
                                  // Otherwise use the value from the database
                                  print(
                                    'Using database alarm_timing for ${plant.speciesName}: ${plant.alarmTiming}',
                                  );
                                  reminderTime = PlantService.formatTimeString(
                                    plant.alarmTiming!,
                                  );
                                } else {
                                  print(
                                    'No reminder time found for ${plant.speciesName}, using "Not Set"',
                                  );
                                }

                                // Return the card
                                return PlantWidgets.buildCareReminderCard(
                                  context: context,
                                  icon: Icons.water_drop,
                                  iconColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors
                                              .green[400]! // Light green for dark mode
                                          : Colors
                                              .green[600]!, // Dark green for light mode
                                  title:
                                      needsWatering
                                          ? 'Water ${plant.speciesName}'
                                          : '${plant.speciesName} watered for today',
                                  time: reminderTime,
                                  color:
                                      needsWatering
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Colors.green,
                                  plant: plant, // Pass plant parameter
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

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
                  future: PlantService.fetchPlants(),
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
                                    color: Colors.green, // Fixed green color
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
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors
                                            .green[900] // Dark mode container
                                        : Colors
                                            .green[100], // Light mode container
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
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors
                                                .green[400] // Light green for dark mode
                                            : Colors
                                                .green[600], // Dark green for light mode
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$healthyPlants',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors
                                                  .green[100] // Light text for dark background
                                              : Colors
                                                  .green[800], // Dark text for light background
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Healthy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.green[100]!.withAlpha((0.7 * 255).round())

                                              : Colors.green[800]!.withAlpha((0.7 * 255).round()),
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
                                          .withAlpha((0.7 * 255).round()),
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
                  future: PlantService.fetchPlants(),
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
                                  PlantWidgets.buildPlantCard(
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
            key: GlobalKey(debugLabel: 'photoUploadSection'),
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
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[900] // Dark mode green
                              : Colors.green[100], // Light mode green
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[400] // Light green for dark mode
                              : Colors.green[600], // Dark green for light mode
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
                      PlantService.showPhotoSourceDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.green[800] // Dark mode button color
                              : Colors.green[600], // Light mode button color
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Select Photo',
                      style: TextStyle(
                        color: Colors.white, // White text for better contrast
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

}
