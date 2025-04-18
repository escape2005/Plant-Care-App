// lib/services/external_link_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/external_link.dart';

class ExternalLinkService {
  final supabase = Supabase.instance.client;

  Future<List<ExternalLink>> getLinksByCategory(String categoryId) async {
    try {
      final response = await supabase
          .from('external_links')
          .select()
          .eq('category_id', categoryId)
          .order('order', ascending: true);
      
      return (response as List).map((data) => ExternalLink.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching external links: $e');
      return [];
    }
  }

  // Add methods for CRUD operations as needed
  Future<void> addLink(ExternalLink link) async {
    try {
      await supabase.from('external_links').insert(link.toJson());
    } catch (e) {
      print('Error adding external link: $e');
      throw e;
    }
  }

  Future<void> updateLink(ExternalLink link) async {
    try {
      await supabase.from('external_links').update(link.toJson()).eq('id', link.id);
    } catch (e) {
      print('Error updating external link: $e');
      throw e;
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await supabase.from('external_links').delete().eq('id', id);
    } catch (e) {
      print('Error deleting external link: $e');
      throw e;
    }
  }
}