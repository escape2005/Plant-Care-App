import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String email = '';
  String phone = '';
  String description = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSupportInfo();
  }

  Future<void> fetchSupportInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('support_info')
          .select('email, phone, description')
          .limit(1)
          .single();

      setState(() {
        email = response['email'] ?? '';
        phone = response['phone'] ?? '';
        description = response['description'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load support information.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: email.isEmpty && phone.isEmpty && description.isEmpty
                  ? Center(
                      child: Text(
                        "No support info available currently.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Email:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Phone:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
    );
  }
}
