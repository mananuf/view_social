import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/abstract_background.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isPhoneMode = false; // Toggle between email and phone

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: DesignTokens.animationNormal,
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: DesignTokens.curveEaseOut,
          ),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine if it's email or phone registration
    final identifier = _identifierController.text.trim();
    final registrationType = identifier.contains('@') ? 'email' : 'phone';

    // Trigger registration event
    context.read<AuthBloc>().add(
      RegisterEvent(
        username: _nameController.text.trim(),
        password: _passwordController.text,
        identifier: identifier,
        registrationType: registrationType,
        displayName: _nameController.text.trim(),
      ),
    );
  }

  void _toggleInputMode() {
    setState(() {
      _isPhoneMode = !_isPhoneMode;
      _identifierController.clear(); // Clear input when switching
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: DesignTokens.animationNormal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Abstract background
          const AbstractBackground(),

          // Content with white card
          Stack(
            children: [
              SafeArea(
                child: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthLoading) {
                      setState(() {
                        _isLoading = true;
                      });
                    } else {
                      setState(() {
                        _isLoading = false;
                      });
                    }

                    if (state is RegisterSuccess) {
                      // Navigate to verification page
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  VerifyEmailPage(
                                    email: _identifierController.text,
                                    verificationType:
                                        state.response.verificationType,
                                    identifier: state.response.identifier,
                                  ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                          transitionDuration: DesignTokens.animationNormal,
                        ),
                      );
                    } else if (state is AuthError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.message,
                            style: DesignTokens.getBodyStyle(
                              context,
                              fontSize: 14,
                              color: AppTheme.white,
                            ),
                          ),
                          backgroundColor: AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: DesignTokens.borderRadiusLg,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      // Back button
                      Padding(
                        padding: DesignTokens.paddingLg,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: AppTheme.white,
                              ),
                            ),
                            Text(
                              'Back',
                              style: DesignTokens.getBodyStyle(
                                context,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // White card - positioned to extend to actual bottom
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: DesignTokens.padding2xl,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: DesignTokens.spaceLg),

                            // Title
                            Center(
                              child: Text(
                                'Create Account',
                                style: DesignTokens.getHeadingStyle(
                                  context,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),

                            SizedBox(height: DesignTokens.space4xl),

                            // Name Field
                            CustomTextField(
                              controller: _nameController,
                              hint: 'Full Name',
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateName,
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppTheme.lightTextSecondary,
                                size: DesignTokens.iconMd,
                              ),
                              size: TextFieldSize.large,
                              variant: TextFieldVariant.outlined,
                            ),

                            SizedBox(height: DesignTokens.spaceLg),

                            // Email/Phone Field
                            CustomTextField(
                              controller: _identifierController,
                              hint: _isPhoneMode
                                  ? 'Phone Number'
                                  : 'Email Address',
                              keyboardType: _isPhoneMode
                                  ? TextInputType.phone
                                  : TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _isPhoneMode
                                  ? Validators.validatePhone
                                  : Validators.validateEmail,
                              prefixIcon: Icon(
                                _isPhoneMode
                                    ? Icons.phone_outlined
                                    : Icons.email_outlined,
                                color: AppTheme.lightTextSecondary,
                                size: DesignTokens.iconMd,
                              ),
                              size: TextFieldSize.large,
                              variant: TextFieldVariant.outlined,
                            ),

                            SizedBox(height: DesignTokens.spaceLg),

                            // Password Field
                            CustomTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              obscureText: !_isPasswordVisible,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validatePassword,
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.lightTextSecondary,
                                size: DesignTokens.iconMd,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.lightTextSecondary,
                                  size: DesignTokens.iconMd,
                                ),
                              ),
                              onSubmitted: (_) => _handleRegister(),
                              size: TextFieldSize.large,
                              variant: TextFieldVariant.outlined,
                            ),

                            SizedBox(height: DesignTokens.space4xl),

                            // Register Button
                            CustomButton(
                              text: 'Sign up',
                              onPressed: _handleRegister,
                              isLoading: _isLoading,
                              fullWidth: true,
                              size: ButtonSize.large,
                              useGradient: true,
                            ),

                            SizedBox(height: DesignTokens.space4xl),

                            // Sign up with text
                            Center(
                              child: Text(
                                'Sign up with',
                                style: DesignTokens.getBodyStyle(
                                  context,
                                  fontSize: 14,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),

                            SizedBox(height: DesignTokens.spaceLg),

                            // Social Login Icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Icon
                                _buildSocialButton(
                                  icon: Icons.g_mobiledata,
                                  onTap: () {
                                    // TODO: Implement Google registration
                                  },
                                ),

                                SizedBox(width: DesignTokens.space2xl),

                                // Apple Icon
                                _buildSocialButton(
                                  icon: Icons.apple,
                                  onTap: () {
                                    // TODO: Implement Apple registration
                                  },
                                ),

                                SizedBox(width: DesignTokens.space2xl),

                                // Phone/Email Toggle Icon
                                _buildSocialButton(
                                  icon: _isPhoneMode
                                      ? Icons.email_outlined
                                      : Icons.phone_outlined,
                                  onTap: _toggleInputMode,
                                  isActive: true,
                                ),
                              ],
                            ),

                            SizedBox(height: DesignTokens.space4xl),

                            // Login Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: DesignTokens.getBodyStyle(
                                      context,
                                      fontSize: 14,
                                      color: AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _navigateToLogin,
                                    child: Text(
                                      'Sign in',
                                      style: DesignTokens.getBodyStyle(
                                        context,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: DesignTokens.space2xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.lightBorderColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightBorderColor, width: 1),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? AppTheme.white : AppTheme.lightTextPrimary,
        ),
      ),
    );
  }
}
