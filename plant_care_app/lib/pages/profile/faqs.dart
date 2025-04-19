import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({Key? key}) : super(key: key);

  @override
  _FAQsPageState createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFAQs();
  }

  Future<void> _fetchFAQs() async {
    try {
      final response = await _supabase
          .from('general_faqs')
          .select()
          .eq('is_active', true)
          .order('order');
      
      setState(() {
        _faqs = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _faqs.isEmpty
              ? const Center(child: Text('No FAQs available'))
              : ListView.builder(
                  itemCount: _faqs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          _faqs[index]['question'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_faqs[index]['answer']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}