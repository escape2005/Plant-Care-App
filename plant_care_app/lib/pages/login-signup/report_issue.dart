import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportIssuePage extends StatefulWidget {
  final String plantName;
  final String plantImageUrl;
  final String adoptionId;

  const ReportIssuePage({
    Key? key,
    required this.plantName,
    required this.plantImageUrl,
    required this.adoptionId,
  }) : super(key: key);

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String? selectedIssue;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final _supabase = Supabase.instance.client;

  final List<String> issueTypes = [
    'Incorrect plant assigned',
    'I do not wish to adopt this plant',
    'I received a different plant',
    'Other (Specify below)',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isOtherSelected => selectedIssue == 'Other (Specify below)';

  Future<void> _submitIssue() async {
    if (selectedIssue == null ||
        (_isOtherSelected && _descriptionController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare the issue text based on selection
      String issueText = selectedIssue!;
      if (_isOtherSelected) {
        issueText = _descriptionController.text;
      } else if (_descriptionController.text.isNotEmpty) {
        // If they selected a predefined issue but also added a description
        issueText = '$selectedIssue: ${_descriptionController.text}';
      }

      // Insert the issue into Supabase
      await _supabase.from('report_issues').insert({
        'issue': issueText,
        'adoption_id': widget.adoptionId,
      });

      // After successfully reporting the issue, delete the adoption record
      await _supabase
          .from('adoption_record')
          .delete()
          .eq('adoption_id', widget.adoptionId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back after successful submission
        Navigator.of(context).pushNamedAndRemoveUntil('/verify', (route) => false);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting issue: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Issue',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Plant Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.plantImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.plantName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Issue Type Section
              const Text(
                'Select Issue Type',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // Issue Type Options
              ...issueTypes.map((issue) {
                final bool isOtherOption = issue == 'Other (Specify below)';
                final bool isDisabled = _isOtherSelected && !isOtherOption;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.grey[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        issue,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDisabled ? Colors.grey : Colors.black,
                        ),
                      ),
                      value: issue,
                      groupValue: selectedIssue,
                      onChanged:
                          isDisabled
                              ? null
                              : (value) {
                                setState(() {
                                  selectedIssue = value;
                                });
                              },
                      activeColor: Colors.green,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Description TextField
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      !_isOtherSelected && selectedIssue != null
                          ? Colors.grey[100]
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  enabled: _isOtherSelected || selectedIssue == null,
                  decoration: InputDecoration(
                    hintText:
                        _isOtherSelected
                            ? 'Please describe your issue here...'
                            : selectedIssue == null
                            ? 'Describe your issue here...'
                            : 'Additional details (optional)',
                    hintStyle: TextStyle(
                      color:
                          !_isOtherSelected && selectedIssue != null
                              ? Colors.grey[400]
                              : Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Submit Issue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _isSubmitting ? Colors.grey : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
