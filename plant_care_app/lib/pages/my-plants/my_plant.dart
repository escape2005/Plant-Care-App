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
      waterFrequencyDays: int.tryParse(
        plantData['water_frequency_days']?.toString() ?? '0',
      ),
      sunlightRequirement: plantData['sunlight_requirement'],
      imageUrl: plantData['image_url'],
      currentAvailability: plantData['current_availability'],
      userId: user.id,
    );
  }).toList();
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
  child: FutureBuilder<List<Map<String, dynamic>>>(
    future: fetchPlantCategories(),
    builder: (context, snapshot) {
      final theme = Theme.of(context);
      final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error loading categories: ${snapshot.error}',
            style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
          ),
        );
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Text(
            'No plant categories found',
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
          ),
        );
      } else {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final category = snapshot.data![index];
            final speciesName = category['species_name'] as String;
            final imageUrl = category['image_url'] as String?;

            final Color? statusColor = index % 2 == 0 ? Colors.green : null;

            return _buildPlantCategoryItem(
              context,
              speciesName,
              imageUrl ?? 'assets/images/plant.jpg',
              statusColor,
            );
          },
        );
      }
    },
  ),
),


          // Second Section - Stats Boxes
  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  child: Row(
    children: [
      // Total Plants
      Expanded(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                '12',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total Plants',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 12),

      // Healthy
      Expanded(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                '8',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Healthy',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 12),

      // Needs Care
      Expanded(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor,
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.healing,
                  color: Theme.of(context).colorScheme.error, size: 28),
              const SizedBox(height: 8),
              Text(
                '4',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Needs Care',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.7),
                  fontSize: 12,
                ),
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
      Text(
        "Today's Plant Care",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 125,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCareReminderCard(
              context:context,
              icon: Icons.water_drop,
              title: 'Water Monstera',
              time: '10:00 AM',
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            _buildCareReminderCard(
              context:context,
              icon: Icons.thermostat,
              title: 'Mist Ferns',
              time: '2:00 PM',
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            _buildCareReminderCard(
              context:context,
              icon: Icons.water_drop,
              title: 'Water Monstera',
              time: '10:00 AM',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
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
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 16),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No plants allocated yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kindly contact the NGO for assistance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          } else {
            return Column(
              children: snapshot.data!.map((plant) {
                return Column(
                  children: [
                    _buildPlantCard(
                      context:context,
                      name: plant.speciesName,
                      species: plant.scientificName,
                      daysSinceWatered: plant.waterFrequencyDays ?? 0,
                      imagePath:
                          plant.imageUrl ?? 'assets/images/plant.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndiPlants(
                              speciesName: plant.speciesName,
                              scientificName: plant.scientificName,
                              imageUrl: plant.imageUrl,
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

Widget _buildPlantCategoryItem(
   BuildContext context, 
  String name,
  String imagePath,
  Color? statusColor,
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
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.eco,
                              size: 30,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    )
                  : null,
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
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                  ),
                ),
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
  );
}


  Widget _buildPlantCard({
  required BuildContext context,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
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
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
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
                  'Last watered: $daysSinceWatered ${daysSinceWatered == 1 ? 'day' : 'days'} ago',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      widthFactor: waterLevel.clamp(0.0, 1.0),
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