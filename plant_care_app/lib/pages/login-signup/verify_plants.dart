import 'package:flutter/material.dart';
import './report_issue.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyPlants extends StatefulWidget {
  const VerifyPlants({super.key});

  @override
  State<VerifyPlants> createState() => _VerifyPlantsState();
}

class _VerifyPlantsState extends State<VerifyPlants> {
  late Future<List<Map<String, dynamic>>> _adoptedPlantsFuture;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _adoptedPlantsFuture = _fetchAdoptedPlantsToVerify();
    _fetchUserInfo();
  }

Future<void> _fetchUserInfo() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user != null) {
    setState(() {
      // The user data comes directly from the auth.currentUser object
      _userName = user.userMetadata?['full_name'] ?? '';
      _userEmail = user.email ?? '';
    });
  }
}

  Future<List<Map<String, dynamic>>> _fetchAdoptedPlantsToVerify() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await supabase
        .from('adoption_record')
        .select('''
          plant_id,
          adoption_date,
          is_verified,
          plant_catalog (
            species_name,
            scientific_name,
            care_difficulty,
            image_url
          )
        ''')
        .eq('user_id', user.id)
        .eq('is_verified', false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _confirmPlants() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      // Update all unverified plants to verified
      await supabase
          .from('adoption_record')
          .update({'is_verified': true})
          .eq('user_id', user.id)
          .eq('is_verified', false);
      
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming plants: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Welcome Section
                Center(
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.eco, size: 80, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Yayy, you have new plants!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // User Info Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Username', _userName ?? 'Loading...'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Email', _userEmail ?? 'Loading...'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Allocated Plants Section
                Text(
                  'Allocated Plants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 20),

                // Plant Cards - Now using FutureBuilder to display actual data
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _adoptedPlantsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading plants: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No plants to verify',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    
                    return Column(
                      children: snapshot.data!.map((plant) {
                        final plantCatalog = plant['plant_catalog'] as Map<String, dynamic>;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlantCard(
                            context,
                            species: plantCatalog['species_name'] ?? 'Unknown Species',
                            scientific: plantCatalog['scientific_name'] ?? 'Unknown Scientific Name',
                            image: plantCatalog['image_url'] ?? '',
                            adoptionDate: plant['adoption_date'] ?? 'Unknown',
                            careDifficulty: plantCatalog['care_difficulty'] ?? 'Unknown',
                            plantId: plant['id'],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Buttons Section
                ElevatedButton(
                  onPressed: _confirmPlants,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),

                // const SizedBox(height: 12),

                // OutlinedButton(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => ReportIssuePage(
                //           plantName: 'Plant Allocation Issue',
                //           plantImageUrl: '',
                //         ),
                //       ),
                //     );
                //   },
                //   style: OutlinedButton.styleFrom(
                //     side: const BorderSide(color: Colors.red),
                //     padding: const EdgeInsets.symmetric(vertical: 15),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text(
                //     'Report Issue',
                //     style: TextStyle(color: Colors.red, fontSize: 16),
                //   ),
                // ),

                const SizedBox(height: 12),

                const Text(
                  'If you have any issues with the allocated plants,\nplease report',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.green[800],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(
    BuildContext context, {
    required String species,
    required String scientific,
    required String image,
    required String adoptionDate,
    required String careDifficulty,
    required dynamic plantId,
  }) {
    // Format adoption date
    String formattedDate = adoptionDate;
    try {
      final date = DateTime.parse(adoptionDate);
      formattedDate = "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      // Use original string if parsing fails
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, size: 40, color: Colors.grey),
                        ),
                      );
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.photo, size: 40, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  species,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  scientific,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Care difficulty
                Row(
                  children: [
                    Text(
                      'Care Difficulty: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      careDifficulty,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: careDifficulty.toLowerCase() == 'easy'
                            ? Colors.green
                            : careDifficulty.toLowerCase() == 'medium'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Adoption date
                Text(
                  'Adoption Date: $formattedDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportIssuePage(
                          plantName: species,
                          plantImageUrl: image,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.report_problem_outlined, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Report issue with this plant',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}