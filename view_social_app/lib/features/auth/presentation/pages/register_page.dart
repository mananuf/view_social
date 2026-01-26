import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/theme/responsive.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
  
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual registration logic with BLoC
      final userData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        'password': _passwordController.text,
        'display_name': _displayNameController.text.trim().isNotEmpty 
            ? _displayNameController.text.trim() 
            : null,
      };
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(); // Go back to login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.getPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                
                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Join VIEW Social',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: Responsive.getFontSize(context, 24),
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account to get started',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: Responsive.getFontSize(context, 16),
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Username Field
                CustomTextField(
                  label: 'Username',
                  hint: 'Choose a unique username',
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateUsername,
                  prefixIcon: const Icon(Icons.person_outlined),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Display Name Field
                CustomTextField(
                  label: 'Display Name (Optional)',
                  hint: 'How others will see your name',
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                
                const SizedBox(height: 16),
                
                // Phone Number Field
                CustomTextField(
                  label: 'Phone Number (Optional)',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePhoneNumber,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                CustomTextField(
                  label: 'Password',
                  hint: 'Create a strong password',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password Field
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  onSubmitted: (_) => _handleRegister(),
                ),
                
                const SizedBox(height: 24),
                
                // Terms and Conditions Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: Responsive.getFontSize(context, 14),
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Register Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),
                
                const SizedBox(height: 16),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: Responsive.getFontSize(context, 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Login',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: Responsive.getFontSize(context, 14),
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}