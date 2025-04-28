import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';
import 'package:plant_care_app/pages/indi-plants/indi_plants.dart';
import 'package:plant_care_app/pages/my-plants/date_time_selector.dart';
import 'package:plant_care_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'adopt_plant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

DateTime selectedDate = DateTime.now();
TimeOfDay selectedTime = TimeOfDay.now();

final bottomNav = const BottomNavScreen();
File? _selectedImage;
bool _isUploading = false;
final _notesController = TextEditingController(); // For plant description
var imageBytes; // To store the image bytes
final userId = supabase.auth.currentUser!.id; // For current user ID
var imagePath; // For storage path

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
  final String? plantId;
  final String? adoptionId; // Added to store the adoption record ID
  String? alarmTiming; // Added to store the alarm timing from adoption_record

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
    this.plantId,
    this.adoptionId,
    this.alarmTiming,
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
      plantId: map['plant_id'],
    );
  }
}

Future<List<Plant>> fetchPlants() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Get adoption records with alarm_timing field
  final response = await supabase
      .from('adoption_record')
      .select('''
      adoption_id,
      plant_id,
      alarm_timing,
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

  List<Plant> plants =
      (response as List).map((data) {
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

Future<bool> _checkIfRequestExists(String plantId) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return false;
  }

  final response = await supabase
      .from('adoption_requests')
      .select()
      .eq('plant_id', plantId)
      .eq('user_id', user.id)
      .limit(1);

  return response.isNotEmpty;
}

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
  bool _isLoadingPreferences = true;

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
      print('MyPlantsScreen state refreshed via public method');
    }
  }

  // Fetch user preferences from Supabase
  Future<void> _fetchUserPreferences() async {
    setState(() {
      _isLoadingPreferences = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      print('Fetching user preferences, current user: ${user?.id}');

      if (user == null) {
        print('User not authenticated');
        setState(() {
          _showPlantCareReminders = false;
          _isLoadingPreferences = false;
        });
        return;
      }

      // Fetch the user's plant_care_remainder preference from user_details table
      print('Querying user_details table for plant_care_remainder');
      final response = await supabase
          .from('user_details')
          .select('plant_care_remainder')
          .eq('id', user.id)
          .limit(1);

      print('Response from user_details table: $response');

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
        print('Empty response or no user record found, defaulting to true');
        setState(() {
          _showPlantCareReminders = true; // Default to true if no record exists
        });
      }
    } catch (e) {
      print('Error fetching user preferences: $e');
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ScrollController scrollController = ScrollController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Section - Horizontal Plant Category Circles
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(vertical: 14),
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
                    height: 125,
                    child: ValueListenableBuilder(
                      valueListenable: _refreshKey,
                      builder: (context, _, __) {
                        return FutureBuilder<List<Plant>>(
                          future: fetchPlants(),
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
                                  reminderTime = _formatTimeString(
                                    _updatedReminderTimes[plant.speciesName]!,
                                  );
                                } else if (plant.alarmTiming != null &&
                                    plant.alarmTiming!.isNotEmpty) {
                                  // Otherwise use the value from the database
                                  print(
                                    'Using database alarm_timing for ${plant.speciesName}: ${plant.alarmTiming}',
                                  );
                                  reminderTime = _formatTimeString(
                                    plant.alarmTiming!,
                                  );
                                } else {
                                  print(
                                    'No reminder time found for ${plant.speciesName}, using "Not Set"',
                                  );
                                }

                                // Return the card
                                return _buildCareReminderCard(
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
                                          : '${plant.speciesName} watered',
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
                                              ? Colors.green[100]!.withOpacity(
                                                0.7,
                                              )
                                              : Colors.green[800]!.withOpacity(
                                                0.7,
                                              ),
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
                      // BACKEND: Handle photo upload
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
                    FutureBuilder<bool>(
                      // Check if the user has already requested this plant
                      future: _checkIfRequestExists(plant['plant_id']),
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
                                  print('Error sending adoption request: $e');
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
    required Color iconColor,
    required String title,
    required String time,
    required Color color,
    required Plant plant, // Added plant parameter
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
                  _showReminderTimeDialog(context, plant);
                },
                tooltip: 'Edit reminder',
              ),
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
      final nowDate = DateTime(now.year, now.month, now.day);
      final newlastWateredDate = DateTime(
        lastWateredDate!.year,
        lastWateredDate!.month,
        lastWateredDate!.day,
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

  void _showReminderTimeDialog(BuildContext context, Plant plant) {
    // Check if there's a saved reminder time in the NotificationService
    String savedReminderTime =
        _updatedReminderTimes[plant.speciesName] ??
        NotificationService.instance.getReminderTime(plant.speciesName);

    bool isReminderSet =
        savedReminderTime != NotificationService.defaultReminderTime &&
        _updatedReminderTimes.containsKey(plant.speciesName);

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

    Future<void> _scheduleNotification() async {
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
          final String adoptionId =
              plant.adoptionId!; // Create local non-nullable variable

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

            print(
              'Updated alarm_timing in database for ${plant.speciesName}: $reminderTimeString',
            );
          } catch (e) {
            print('Error updating database: $e');
            throw e; // Re-throw to be caught by the outer try-catch
          }
        } else {
          print(
            'Cannot update database: missing adoption_id for ${plant.speciesName}',
          );
        }

        // Update the local map for immediate UI update
        setState(() {
          _updatedReminderTimes[plant.speciesName] = reminderTimeString;
          // Increment refresh key to trigger UI update
          _refreshKey.value++;
        });

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

    void _updateDateTime(DateTime date, TimeOfDay time, Plant plant) {
      setState(() {
        selectedDate = date;
        selectedTime = time;
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      _updateDateTime(selectedDate, selectedTime, plant);
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
                    _scheduleNotification();
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

  String _formatTimeString(String timeString) {
    if (timeString == "Not Set") {
      return timeString;
    }

    print('Formatting time string: $timeString');

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
    print('Could not parse time string: $timeString');
    return timeString;
  }

  // Add these methods around line 1177 (before _sendTestNotification method)
  void _showPhotoSourceDialog(BuildContext context) {
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
                  _pickImageFromSource(ImageSource.gallery);
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
                  _pickImageFromSource(ImageSource.camera);
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

  Future<void> _pickImageFromSource(ImageSource source) async {
    // Request camera permission if using camera
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera permission is required to take a photo'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
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
        setState(() {
          _selectedImage = File(image.path);
        });
        _showImagePreviewDialog(context);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog(BuildContext context) {
    // Add a state variable to track the selected plant
    String? _selectedPlantId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            // Add this to make content scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Plant Photo Preview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.35, // Reduced from 0.4 to give more room
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: FutureBuilder<List<Plant>>(
                    future: fetchPlants(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error loading plants: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No plants available');
                      } else {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Link to your plant',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                              hint: const Text('Select a plant'),
                              value: _selectedPlantId,
                              items:
                                  snapshot.data!.map((Plant plant) {
                                    return DropdownMenuItem<String>(
                                      value: plant.plantId,
                                      child: Text(plant.speciesName),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPlantId = newValue;
                                });
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add notes about this plant (optional)',
                      labelText: 'Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                          onPressed:
                              _isUploading
                                  ? null
                                  : () => _sendImageToNGO(
                                    context,
                                    _selectedPlantId,
                                  ),
                          child:
                              _isUploading
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                          strokeWidth: 2.0,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Sending...'),
                                    ],
                                  )
                                  : const Text(
                                    'Send to NGO',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showPhotoSourceDialog(context);
                          },
                          child: Text(
                            'Choose Different Photo',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future _sendImageToNGO(
    BuildContext context,
    String? selectedPlantId, {
    String? adoptionId, // Add adoptionId parameter
  }) async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Create a unique path for the image
      final imagePath = '/$userId/${DateTime.now().millisecondsSinceEpoch}';

      // Convert File to Uint8List
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();

      // Upload image to Supabase storage
      await supabase.storage
          .from('community-images')
          .uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      // Prepare data for the database
      final Map imageData = {
        'user_id': userId,
        'image_path': imagePath,
        'notes': _notesController.text,
      };

      // Add plant_id if one was selected
      if (selectedPlantId != null && selectedPlantId.isNotEmpty) {
        imageData['plant_id'] = selectedPlantId;
      }

      // Save record to user_plants_images table
      await supabase.from('user_plants_images').insert(imageData);

      // Also update daily_activity to record watering if adoptionId is provided
      if (adoptionId != null && adoptionId.isNotEmpty) {
        final now = DateTime.now().toUtc().toIso8601String();

        await supabase.from('daily_activity').insert({
          'user_id': userId,
          'adoption_id': adoptionId,
          'activity_time': now,
        });

        // You might want to update UI state related to watering if needed
        // For example, if this component also tracks watering status:
        // setState(() {
        //   wateredDays.add(DateTime.now());
        //   wateredToday = true;
        // });
      }

      if (mounted) {
        Navigator.pop(context); // Close the preview dialog

        // Clear the notes field after successful upload
        _notesController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adoptionId != null
                  ? 'Plant photo sent and watering recorded!'
                  : 'Your plant photo has been sent to the NGO experts!',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error uploading image or recording watering: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _sendTestNotification() {
    print("Notification sent!");
    NotificationService.instance.sendTestNotification();
  }
}
