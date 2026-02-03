import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/widgets/abstract_background.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          const AbstractBackground(),

          // Content overlay - Three layers only
          Column(
            children: [
              // Layer 1 & 2: Welcome Text and Tagline (Centered)
              Expanded(
                child: SafeArea(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Padding(
                        padding: Responsive.getHorizontalPadding(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome to VIEW',
                              style: DesignTokens.getHeadingStyle(
                                context,
                                fontSize: Responsive.responsive<double>(
                                  context,
                                  mobile: 36,
                                  tablet: 42,
                                  desktop: 48,
                                ),
                                fontWeight: FontWeight.w800, // Extra bold
                                color: AppTheme.white,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: DesignTokens.spaceLg),

                            // Tagline
                            Text(
                              'Connect, Share, and Pay with ease',
                              style: DesignTokens.getBodyStyle(
                                context,
                                fontSize: Responsive.responsive<double>(
                                  context,
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),
                                color: AppTheme.white.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 3: Bottom Buttons (Side by side, no overlap)
              Row(
                children: [
                  // Sign in button (left side, dark style)
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToLogin,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sign in',
                            style: DesignTokens.getBodyStyle(
                              context,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sign up button (right side, white style with curved top-left edge)
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToRegister,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(
                              32,
                            ), // Only curved top-left
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sign up',
                            style: DesignTokens.getBodyStyle(
                              context,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
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
        ],
      ),
    );
  }
}
