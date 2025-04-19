import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_details')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _nameController.text = response['user_name'] ?? '';
          _usernameController.text = response['username'] ?? '';
          _bioController.text = response['bio'] ?? '';
          _emailController.text = response['user_email'] ?? user.email ?? '';
          _locationController.text = response['location'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_details').update({
          'user_name': _nameController.text,
          'username': _usernameController.text,
          'bio': _bioController.text,
          'location': _locationController.text,
        }).eq('id', user.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Picture Section (keep existing)
              // ... [Keep your existing profile picture code] ...
              
              // Form Fields
              _buildFormField(
                context, 
                Icons.person_outline, 
                AppLocalizations.of(context)!.name,
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                context, 
                Icons.alternate_email, 
                AppLocalizations.of(context)!.username,
                controller: _usernameController,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                context, 
                Icons.info_outline, 
                AppLocalizations.of(context)!.bio, 
                controller: _bioController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                context, 
                Icons.email_outlined, 
                AppLocalizations.of(context)!.email,
                controller: _emailController,
                enabled: false, // Email should be read-only
              ),
              const SizedBox(height: 20),
              _buildFormField(
                context, 
                Icons.location_on_outlined, 
                AppLocalizations.of(context)!.location,
                controller: _locationController,
              ),
              const SizedBox(height: 40),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.saveChanges,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context,
    IconData icon,
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: enabled ? Colors.grey[200] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}