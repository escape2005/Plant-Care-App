import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isVerified = false;
  bool _isLoading = false;
  String? _currentPasswordError;

  Future<void> _verifyCurrentPassword() async {
    if (_currentPassController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentPasswordError = null;
    });
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: user.email!,
          password: _currentPassController.text,
        );
        setState(() => _isVerified = true);
      }
    } catch (e) {
      setState(() {
        _isVerified = false;
        _currentPasswordError = 'Incorrect password';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPassController.text),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                controller: _currentPassController,
                label: 'Current Password',
                hint: 'Enter current password',
                verified: _isVerified,
                errorText: _currentPasswordError,
              ),
              if (!_isVerified) ...[
                const SizedBox(height: 20),
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
                    onPressed: _isLoading ? null : _verifyCurrentPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
              if (_isVerified) ...[
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _newPassController,
                  label: 'New Password',
                  hint: 'Enter new password',
                  isNew: true,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _confirmPassController,
                  label: 'Confirm Password',
                  hint: 'Re-enter new password',
                  isNew: true,
                  validator: (value) {
                    if (value != _newPassController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
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
                    onPressed: _isLoading ? null : _updatePassword,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save New Password',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool verified = false,
    bool isNew = false,
    FormFieldValidator<String>? validator,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: verified ? Colors.green.withOpacity(0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: verified ? Colors.green : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: true,
            enabled: !verified || isNew,
            validator: validator,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}