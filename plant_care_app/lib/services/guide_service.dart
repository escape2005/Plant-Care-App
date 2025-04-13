// lib/services/guide_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guide.dart';

class GuideService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all guides for a specific category
  Future<List<Guide>> getGuidesByCategory(String category) async {
    try {
      final response = await _client
          .from('guides')
          .select()
          .eq('category', category.toLowerCase())
          .order('created_at', ascending: false);

      return (response as List).map((guide) => Guide.fromJson(guide)).toList();
    } catch (e) {
      print('Error fetching guides: $e');
      return [];
    }
  }

  // Get a single guide by ID
  Future<Guide?> getGuideById(int id) async {
    try {
      final response = await _client
          .from('guides')
          .select()
          .eq('id', id)
          .single();

      return Guide.fromJson(response);
    } catch (e) {
      print('Error fetching guide: $e');
      return null;
    }
  }

  // Get count of guides for each category
  // Get count of guides for each category
Future<Map<String, int>> getGuideCounts() async {
  try {
    // First, get all guides with their categories
    final response = await _client
        .from('guides')
        .select('category');
    
    // Manually count guides per category
    Map<String, int> counts = {};
    for (var row in response) {
      String category = row['category'];
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  } catch (e) {
    print('Error fetching guide counts: $e');
    return {};
  }
}

  // Create a new guide
  Future<Guide?> createGuide({
    required String title,
    required String category,
    required String content,
    String? summary,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.from('guides').insert({
        'title': title,
        'category': category.toLowerCase(),
        'content': content,
        'summary': summary,
        'image_url': imageUrl,
      }).select();

      return Guide.fromJson(response[0]);
    } catch (e) {
      print('Error creating guide: $e');
      return null;
    }
  }

  // Update an existing guide
  Future<Guide?> updateGuide({
    required int id,
    required String title,
    required String category,
    required String content,
    String? summary,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.from('guides').update({
        'title': title,
        'category': category.toLowerCase(),
        'content': content,
        'summary': summary,
        'image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id).select();

      return Guide.fromJson(response[0]);
    } catch (e) {
      print('Error updating guide: $e');
      return null;
    }
  }

  // Delete a guide
  Future<bool> deleteGuide(int id) async {
    try {
      await _client.from('guides').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting guide: $e');
      return false;
    }
  }
}