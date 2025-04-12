import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';
import 'package:plant_care_app/pages/indi-plants/indi_plants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  });

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      speciesName: map['species_name'] ?? '',
      scientificName: map['scientific_name'] ?? '',
      description: map['description'],
      careDifficulty: map['care_difficulty'],
      waterFrequencyDays: int.tryParse(map['water_frequency_days'] ?? '0'),
      sunlightRequirement: map['sunlight_requirement'],
      imageUrl: map['image_url'],
      currentAvailability: map['current_availability'],
      userId: map['user_id'] ?? '',
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
        plant_id,
        plant_catalog (
          species_name,
          scientific_name,
          description,
          care_difficulty,
          water_frequency_days,
          sunlight_requirement,
          image_url,
          current_availability
        )
      ''')
      .eq('user_id', user.id);

  return (response as List).map((data) {
    final plantData = data['plant_catalog'] as Map<String, dynamic>;
    return Plant(
      speciesName: plantData['species_name'] ?? '',
      scientificName: plantData['scientific_name'] ?? '',
      description: plantData['description'],
      careDifficulty: plantData['care_difficulty'],
      waterFrequencyDays: int.tryParse(plantData['water_frequency_days']?.toString() ?? '0'),
      sunlightRequirement: plantData['sunlight_requirement'],
      imageUrl: plantData['image_url'],
      currentAvailability: plantData['current_availability'],
      userId: user.id,
    );
  }).toList();
}

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Section - Horizontal Plant Category Circles
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPlantCategoryItem(
                  'Monstera',
                  'assets/images/plant.jpg',
                  Colors.green,
                ),
                _buildPlantCategoryItem(
                  'Snake Plant',
                  'assets/images/plant.jpg',
                  null,
                ),
                _buildPlantCategoryItem(
                  'Pothos',
                  'assets/images/plant.jpg',
                  Colors.green,
                ),
                _buildPlantCategoryItem(
                  'Fiddle Fig',
                  'assets/images/plant.jpg',
                  null,
                ),
                _buildPlantCategoryItem(
                  'Peace Lily',
                  'assets/images/plant.jpg',
                  Colors.green,
                ),
                // BACKEND: More plant categories can be added dynamically here
              ],
            ),
          ),

          // Second Section - Stats Boxes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, color: Colors.green, size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          '12',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total Plants',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(),
                          spreadRadius: 1,
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
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '8',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Healthy',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFCE1E0),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.healing, color: Colors.green, size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          '4',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Needs Care',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Third Section - Today's Plant Care
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Plant Care",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 125,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCareReminderCard(
                        icon: Icons.water_drop,
                        title: 'Water Monstera',
                        time: '10:00 AM',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildCareReminderCard(
                        icon: Icons.thermostat,
                        title: 'Mist Ferns',
                        time: '2:00 PM',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildCareReminderCard(
                        icon: Icons.water_drop,
                        title: 'Water Monstera',
                        time: '10:00 AM',
                        color: Colors.green,
                      ),
                      // BACKEND: More care reminders can be added dynamically here
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fourth Section - All Plants
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "All Plants",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Replace the existing FutureBuilder section with this updated code
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
                            color: Colors.red[600],
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
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No plants allocated yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kindly contact the NGO for assistance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children:
                            snapshot.data!.map((plant) {
                              return Column(
                                children: [
                                  _buildPlantCard(
                                    name: plant.speciesName,
                                    species: plant.scientificName,
                                    daysSinceWatered:
                                        plant.waterFrequencyDays ?? 0,
                                    imagePath:
                                        plant.imageUrl ??
                                        'assets/images/plant.jpg',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => IndiPlants(speciesName: plant.speciesName, scientificName: plant.scientificName, imageUrl: plant.imageUrl,),
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
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 220, 220, 220),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add your plant photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your plant with our NGO experts',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // BACKEND: Handle photo upload
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF94),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Select Photo',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildPlantCategoryItem(
    String name,
    String imagePath,
    Color? statusColor,
  ) {
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
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (statusColor != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCareReminderCard({
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPlantCard({
    required String name,
    required String species,
    int daysSinceWatered = 0,
    double waterLevel = 0,
    required String imagePath,
    Color statusColor = Colors.green,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.35),
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
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 🌱 Plant info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Scientific Name: ${species}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last watered: $daysSinceWatered ${daysSinceWatered == 1 ? 'day' : 'days'} ago',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  // 💧 Water level progress bar
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: waterLevel.clamp(0.6, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade400,
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
    );
  }
}
