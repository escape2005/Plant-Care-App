// lib/services/faq_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faq.dart';

class FAQService {
  final supabase = Supabase.instance.client;

  Future<List<FAQ>> getFaqs() async {
    try {
      final response = await supabase
          .from('faqs')
          .select()
          .order('order', ascending: true);
      
      return (response as List).map((data) => FAQ.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  // Optional: Get FAQs for a specific category
  Future<List<FAQ>> getFaqsByCategory(String categoryId) async {
    try {
      final response = await supabase
          .from('faqs')
          .select()
          .eq('category_id', categoryId)
          .order('order', ascending: true);
      
      return (response as List).map((data) => FAQ.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching FAQs by category: $e');
      return [];
    }
  }

  // Add methods for CRUD operations as needed
  Future<void> addFaq(FAQ faq) async {
    try {
      await supabase.from('faqs').insert(faq.toJson());
    } catch (e) {
      print('Error adding FAQ: $e');
      throw e;
    }
  }

  Future<void> updateFaq(FAQ faq) async {
    try {
      await supabase.from('faqs').update(faq.toJson()).eq('id', faq.id);
    } catch (e) {
      print('Error updating FAQ: $e');
      throw e;
    }
  }

  Future<void> deleteFaq(String id) async {
    try {
      await supabase.from('faqs').delete().eq('id', id);
    } catch (e) {
      print('Error deleting FAQ: $e');
      throw e;
    }
  }
}