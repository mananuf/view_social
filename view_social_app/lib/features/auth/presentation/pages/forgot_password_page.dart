import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import 'home_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _useEmail = true; // Toggle between email and phone recovery
  
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.curveEaseOut,
    ));

    _slideController.forward();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual password reset logic with BLoC
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        _showSnackBar(
          _useEmail 
            ? 'Password reset link sent to your email'
            : 'Password reset code sent to your phone',
          AppTheme.successColor,
        );
        
        // Navigate to home page (simulating successful reset)
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: DesignTokens.animationNormal,
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Password reset failed: ${e.toString()}', AppTheme.errorColor);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DesignTokens.getBodyStyle(context, fontSize: 14, color: AppTheme.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusLg,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: DesignTokens.paddingLg,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: Responsive.getHorizontalPadding(context),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: DesignTokens.space4xl),
                        
                        // Title
                        Text(
                          'Forgot',
                          style: DesignTokens.getHeadingStyle(
                            context,
                            fontSize: Responsive.responsive<double>(
                              context,
                              mobile: 32,
                              tablet: 36,
                              desktop: 40,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Password?',
                          style: DesignTokens.getHeadingStyle(
                            context,
                            fontSize: Responsive.responsive<double>(
                              context,
                              mobile: 32,
                              tablet: 36,
                              desktop: 40,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTextPrimary,
                          ),
                        ),
                        
                        SizedBox(height: DesignTokens.spaceLg),
                        
                        // Subtitle
                        Text(
                          'Select which contact details should we use to reset your password',
                          style: DesignTokens.getBodyStyle(
                            context,
                            fontSize: 14,
                            color: AppTheme.lightTextSecondary,
                          ),
                        ),
                        
                        SizedBox(height: DesignTokens.space4xl),
                        
                        // Recovery Method Selection
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: DesignTokens.borderRadiusXl,
                            border: Border.all(
                              color: AppTheme.lightBorderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Email Option
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _useEmail = true;
                                  });
                                },
                                child: Container(
                                  padding: DesignTokens.paddingLg,
                                  decoration: BoxDecoration(
                                    color: _useEmail 
                                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: DesignTokens.borderRadiusLg,
                                        ),
                                        child: const Icon(
                                          Icons.email_outlined,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: DesignTokens.spaceLg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'via Email:',
                                              style: DesignTokens.getBodyStyle(
                                                context,
                                                fontSize: 14,
                                                color: AppTheme.lightTextSecondary,
                                              ),
                                            ),
                                            Text(
                                              'and***ley@yourdomain.com',
                                              style: DesignTokens.getBodyStyle(
                                                context,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.lightTextPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_useEmail)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Divider
                              Container(
                                height: 1,
                                color: AppTheme.lightBorderColor,
                                margin: DesignTokens.paddingHorizontalLg,
                              ),
                              
                              // Phone Option
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _useEmail = false;
                                  });
                                },
                                child: Container(
                                  padding: DesignTokens.paddingLg,
                                  decoration: BoxDecoration(
                                    color: !_useEmail 
                                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: DesignTokens.borderRadiusLg,
                                        ),
                                        child: const Icon(
                                          Icons.phone_outlined,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: DesignTokens.spaceLg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'via SMS:',
                                              style: DesignTokens.getBodyStyle(
                                                context,
                                                fontSize: 14,
                                                color: AppTheme.lightTextSecondary,
                                              ),
                                            ),
                                            Text(
                                              '+1 111 ******99',
                                              style: DesignTokens.getBodyStyle(
                                                context,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.lightTextPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!_useEmail)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: DesignTokens.space6xl),
                        
                        // Continue Button
                        CustomButton(
                          text: 'Continue',
                          onPressed: _handlePasswordReset,
                          isLoading: _isLoading,
                          fullWidth: true,
                          size: ButtonSize.large,
                        ),
                      ],
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
}