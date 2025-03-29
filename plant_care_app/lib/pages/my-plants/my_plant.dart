import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/bottom_nav.dart';

final bottomNav = const BottomNavScreen();

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
                _buildPlantCategoryItem('Monstera', 'assets/images/plant.jpg', Colors.green),
                _buildPlantCategoryItem('Snake Plant', 'assets/images/plant.jpg', null),
                _buildPlantCategoryItem('Pothos', 'assets/images/plant.jpg', Colors.green),
                _buildPlantCategoryItem('Fiddle Fig', 'assets/images/plant.jpg', null),
                _buildPlantCategoryItem('Peace Lily', 'assets/images/plant.jpg', Colors.green),
                _buildPlantCategoryItem('Peace Lily', 'assets/images/plant.jpg', Colors.green),
                _buildPlantCategoryItem('Peace Lily', 'assets/images/plant.jpg', Colors.green),
                _buildPlantCategoryItem('Peace Lily', 'assets/images/plant.jpg', Colors.green),
                _buildPlantCategoryItem('Peace Lily', 'assets/images/plant.jpg', Colors.green),
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
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
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
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
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
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
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
                          style: TextStyle(
                            color: Colors.grey,
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
                const Text(
                  "Today's Plant Care",
                  style: TextStyle(
                    fontSize: 20,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "All Plants",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPlantCard(
                  name: 'Monstera Deliciosa',
                  species: 'Monstera',
                  daysSinceWatered: 2,
                  waterLevel: 0.7,
                  imagePath: 'assets/images/plant.jpg',
                  statusColor: Colors.green,
                  onTap: () {
                    // BACKEND: Navigate to plant detail page
                  },
                ),
                const SizedBox(height: 16),
                _buildPlantCard(
                  name: 'Snake Plant',
                  species: 'Sansevieria',
                  daysSinceWatered: 5,
                  waterLevel: 0.6,
                  imagePath: 'assets/images/plant.jpg',
                  statusColor: Colors.amber,
                  onTap: () {
                    // BACKEND: Navigate to plant detail page
                  },
                ),
                const SizedBox(height: 16),
                _buildPlantCard(
                  name: 'Golden Pothos',
                  species: 'Epipremnum aureum',
                  daysSinceWatered: 1,
                  waterLevel: 0.9,
                  imagePath: 'assets/images/plant.jpg',
                  statusColor: Colors.green,
                  onTap: () {
                    // BACKEND: Navigate to plant detail page
                  },
                ),
                // BACKEND: More plant cards can be added dynamically here
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your plant with our NGO experts',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
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

  Widget _buildPlantCategoryItem(String name, String imagePath, Color? statusColor) {
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard({
    required String name,
    required String species,
    required int daysSinceWatered,
    required double waterLevel,
    required String imagePath,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
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
                    species,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last watered: $daysSinceWatered ${daysSinceWatered == 1 ? 'day' : 'days'} ago',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        widthFactor: waterLevel,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade700, Colors.green.shade400],
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