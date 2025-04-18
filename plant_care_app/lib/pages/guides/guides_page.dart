// lib/pages/guides/guides_page.dart
import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/faq.dart';
import '../../services/guide_service.dart';
import '../../services/guide_category_service.dart';
import '../../services/faq_service.dart';
import 'guides_list_page.dart';

class GuidesPage extends StatefulWidget {
  const GuidesPage({Key? key}) : super(key: key);

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  List<FAQ> faqs = [];

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
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
          faqs = snapshot.data!['faqs'] as List<FAQ>;
          
          return SingleChildScrollView(
            child: Column(
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
                SizedBox(
                  height: 220, // Fixed height for the grid
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
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
                
                // FAQs Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                
                // FAQs Accordion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildFaqsAccordion(),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Updated FAQs Accordion Builder with fix for expansion issue
  Widget _buildFaqsAccordion() {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: const EdgeInsets.all(0),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          // This is the key fix - toggle the expansion state correctly
          faqs[index].isExpanded = !faqs[index].isExpanded;
        });
      },
      children: faqs.map<ExpansionPanel>((FAQ faq) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(
                faq.question,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.answer,
                  style: TextStyle(
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
          isExpanded: faq.isExpanded,
        );
      }).toList(),
    );
  }

  // Method to load categories, counts, and FAQs
  Future<Map<String, dynamic>> _loadData() async {
    // Fetch categories from the database
    final categoryService = GuideCategoryService();
    final List<GuideCategory> categories = await categoryService.getCategories();

    // Get guide counts for each category
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

    // Fetch FAQs
    final faqService = FAQService();
    final List<FAQ> faqs = await faqService.getFaqs();

    return {
      'categories': categories,
      'counts': counts,
      'faqs': faqs,
    };
  }
}