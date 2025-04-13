// lib/pages/guides/guides_page.dart
import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../services/guide_service.dart';
import 'guides_list_page.dart';

class GuidesPage extends StatelessWidget {
  const GuidesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define guide categories with their icons
    final List<GuideCategory> categories = [
      GuideCategory(
        title: 'Watering',
        icon: Icons.water_drop_outlined,
        count: 0, // Will be updated from DB
        color: Colors.green.shade100,
        textColor: Colors.green.shade800,
      ),
      GuideCategory(
        title: 'Pruning',
        icon: Icons.content_cut_outlined,
        count: 0, // Will be updated from DB
        color: Colors.green.shade100,
        textColor: Colors.green.shade800,
      ),
      GuideCategory(
        title: 'Pest Control',
        icon: Icons.warning_amber_outlined,
        count: 0, // Will be updated from DB
        color: Colors.green.shade100,
        textColor: Colors.green.shade800,
      ),
      GuideCategory(
        title: 'Light',
        icon: Icons.wb_sunny_outlined,
        count: 0, // Will be updated from DB
        color: Colors.green.shade100,
        textColor: Colors.green.shade800,
      ),
    ];

    return Scaffold(
      body: FutureBuilder<Map<String, int>>(
        future: GuideService().getGuideCounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final counts = snapshot.data!;
            // Update the counts for each category
            for (var i = 0; i < categories.length; i++) {
              final category = categories[i];
              categories[i] = GuideCategory(
                title: category.title,
                icon: category.icon,
                count: counts[category.title.toLowerCase()] ?? 0,
                color: category.color,
                textColor: category.textColor,
              );
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Plant Care Guides',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GuidesListPage(category: category),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category.icon,
                                color: category.textColor,
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                category.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: category.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${category.count} guides',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}