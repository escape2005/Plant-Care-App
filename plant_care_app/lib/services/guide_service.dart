// lib/services/guide_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guide.dart';

class GuideService {
  final supabase = Supabase.instance.client;

  Future<Map<String, int>> getGuideCounts() async {
    try {
      final response = await supabase
          .from('guides')
          .select('category, id');

      // Group by category and count
      final Map<String, int> counts = {};
      for (var item in response) {
        final categoryId = item['category'];
        counts[categoryId] = (counts[categoryId] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      print('Error fetching guide counts: $e');
      return {};
    }
  }

  Future<List<Guide>> getGuidesByCategory(String categoryId) async {
    try {
      final response = await supabase
          .from('guides')
          .select('*')
          .eq('category', categoryId)
          .order('created_at');

      return (response as List).map<Guide>((data) => Guide.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching guides by category: $e');
      return [];
    }
  }

  // Your other methods...
}