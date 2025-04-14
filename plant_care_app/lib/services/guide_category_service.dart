// lib/services/guide_category_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guide.dart';
import 'package:flutter/material.dart';

class GuideCategoryService {
  final supabase = Supabase.instance.client;

  Future<List<GuideCategory>> getCategories() async {
    try {
      final response = await supabase
          .from('guide_category')
          .select('id, title, icon_url')
          .order('created_at');

      return response.map<GuideCategory>((category) {
        return GuideCategory(
          id: category['id'],
          title: category['title'],
          icon: _getIconData(category['icon_url']),
          count: 0, // Will be filled later
          color: Colors.green.shade100,
          textColor: Colors.green.shade800,
        );
      }).toList();
    } catch (e) {
      print('Error fetching guide categories: $e');
      return [];
    }
  }

  // Helper method to map icon strings from database to actual Icons
  IconData _getIconData(String iconName) {
    final iconMap = {
      'water_drop': Icons.water_drop_outlined,
      'content_cut': Icons.content_cut_outlined,
      'warning_amber': Icons.warning_amber_outlined,
      'wb_sunny': Icons.wb_sunny_outlined,
      'eco': Icons.eco_outlined,
      'thermostat': Icons.thermostat_outlined,
      // Add more mappings as needed
    };
    
    return iconMap[iconName] ?? Icons.help_outline; // Default icon if not found
  }
}