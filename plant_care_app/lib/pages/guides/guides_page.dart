// lib/pages/guides/guides_page.dart
import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../services/guide_service.dart';
import '../../services/guide_category_service.dart';
import 'guides_list_page.dart';

class GuidesPage extends StatelessWidget {
  const GuidesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadCategoriesAndCounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!['categories'].isEmpty) {
            return const Center(child: Text('No guide categories found'));
          }

          final categories = snapshot.data!['categories'] as List<GuideCategory>;
          
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
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category.icon,
                                color: category.textColor,
                                size: 20,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                category.title,
                                style: TextStyle(
                                  fontSize: 16,
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

  // Method to load both categories and their guide counts
  Future<Map<String, dynamic>> _loadCategoriesAndCounts() async {
    // First, fetch categories from the database
    final categoryService = GuideCategoryService();
    final List<GuideCategory> categories = await categoryService.getCategories();

    // Then get guide counts for each category
    final guideService = GuideService();
    final Map<String, int> counts = await guideService.getGuideCounts();

    // Update each category with its count
    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      categories[i] = GuideCategory(
        id: category.id,
        title: category.title,
        icon: category.icon,
        count: counts[category.id] ?? 0,
        color: Colors.green.shade100,
        textColor: Colors.green.shade800,
      );
    }

    return {
      'categories': categories,
      'counts': counts,
    };
  }
}