import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/abstract_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
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
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
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

        // Navigate back to login page
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Password reset failed: ${e.toString()}',
          AppTheme.errorColor,
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

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: 14,
            color: AppTheme.white,
          ),
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
      body: Stack(
        children: [
          // Abstract background
          const AbstractBackground(),

          // Content structure
          Column(
            children: [
              // Safe area for back button only
              SafeArea(
                bottom: false, // Don't apply safe area to bottom
                child: Padding(
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
              ),

              // Spacer to push content down
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),

              // White card with rounded top corners - extends to very bottom
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      top: false, // Don't apply safe area to top
                      child: SingleChildScrollView(
                        padding: DesignTokens.padding2xl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: DesignTokens.spaceLg),

                            // Title
                            Center(
                              child: Text(
                                'Forgot Password?',
                                style: DesignTokens.getHeadingStyle(
                                  context,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),

                            SizedBox(height: DesignTokens.spaceLg),

                            // Subtitle
                            Center(
                              child: Text(
                                'Select which contact details should we use to reset your password',
                                textAlign: TextAlign.center,
                                style: DesignTokens.getBodyStyle(
                                  context,
                                  fontSize: 14,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),

                            SizedBox(height: DesignTokens.space4xl),

                            // Recovery Method Selection
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.lightSurfaceColor,
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
                                            ? AppTheme.primaryColor.withValues(
                                                alpha: 0.1,
                                              )
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
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  DesignTokens.borderRadiusLg,
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'via Email:',
                                                  style:
                                                      DesignTokens.getBodyStyle(
                                                        context,
                                                        fontSize: 14,
                                                        color: AppTheme
                                                            .lightTextSecondary,
                                                      ),
                                                ),
                                                Text(
                                                  'and***ley@yourdomain.com',
                                                  style:
                                                      DesignTokens.getBodyStyle(
                                                        context,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppTheme
                                                            .lightTextPrimary,
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
                                            ? AppTheme.primaryColor.withValues(
                                                alpha: 0.1,
                                              )
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
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  DesignTokens.borderRadiusLg,
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'via SMS:',
                                                  style:
                                                      DesignTokens.getBodyStyle(
                                                        context,
                                                        fontSize: 14,
                                                        color: AppTheme
                                                            .lightTextSecondary,
                                                      ),
                                                ),
                                                Text(
                                                  '+1 111 ******99',
                                                  style:
                                                      DesignTokens.getBodyStyle(
                                                        context,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppTheme
                                                            .lightTextPrimary,
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

                            SizedBox(height: DesignTokens.space4xl),

                            // Continue Button
                            CustomButton(
                              text: 'Continue',
                              onPressed: _handlePasswordReset,
                              isLoading: _isLoading,
                              fullWidth: true,
                              size: ButtonSize.large,
                              useGradient: true,
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
}
