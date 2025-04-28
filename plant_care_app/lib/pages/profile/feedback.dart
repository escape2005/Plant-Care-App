import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;
  final _supabase = Supabase.instance.client;

  final List<String> _categories = [
    'General',
    'Bug Report',
    'Feature Request',
    'UI/UX',
    'Performance',
    'Other'
  ];

  // Helper method to translate category while keeping database values consistent
  String _translateCategory(String category, BuildContext context) {
    switch (category) {
      case 'General':
        return AppLocalizations.of(context)!.generalCategory;
      case 'Bug Report':
        return AppLocalizations.of(context)!.bugReportCategory;
      case 'Feature Request':
        return AppLocalizations.of(context)!.featureRequestCategory;
      case 'UI/UX':
        return AppLocalizations.of(context)!.uiUxCategory;
      case 'Performance':
        return AppLocalizations.of(context)!.performanceCategory;
      case 'Other':
        return AppLocalizations.of(context)!.otherCategory;
      default:
        return category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user ID if user is logged in
      final userId = _supabase.auth.currentUser?.id;
      
      // Submit feedback to Supabase (original comment maintained)
      await _supabase.from('feedback').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'message': _feedbackController.text,
        'category': _selectedCategory,
        'user_id': userId, // Will be null if not logged in (original comment)
        'status': 'new', // Default status for new feedback (original comment)
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        // Reset form (original comment maintained)
        _nameController.clear();
        _emailController.clear();
        _feedbackController.clear();
        setState(() {
          _selectedCategory = 'General';
        });
        
        // Show success message (original comment maintained)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.feedbackSuccess),
            backgroundColor: const Color.fromRGBO(46, 125, 50, 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        // Show error message (original comment maintained)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.feedbackError}${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.feedbackTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with icon (original comment maintained)
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.feedback_outlined,
                        size: 60,
                        color: Color.fromRGBO(46, 125, 50, 1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.feedbackHeader,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.feedbackSubheader,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Name field (original comment maintained)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.nameLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.nameValidation;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email field (original comment maintained)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.emailLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.emailValidationEmpty;
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return AppLocalizations.of(context)!.emailValidationInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category dropdown (original comment maintained)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.categoryLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_translateCategory(category, context)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Feedback message field (original comment maintained)
                TextFormField(
                  controller: _feedbackController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.feedbackLabel,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText: AppLocalizations.of(context)!.feedbackHint,
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.feedbackValidationEmpty;
                    }
                    if (value.length < 10) {
                      return AppLocalizations.of(context)!.feedbackValidationLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Submit button (original comment maintained)
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color.fromRGBO(46, 125, 50, 1),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.of(context)!.submitButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}