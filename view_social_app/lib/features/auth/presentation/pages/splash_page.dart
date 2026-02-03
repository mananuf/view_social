import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/services/auth_service.dart';
import 'welcome_page.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: DesignTokens.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: DesignTokens.curveEaseOut,
      ),
    );

    _fadeController.forward();
  }

  void _checkAuthAndNavigate() async {
    // Wait for splash animation to complete
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if user is authenticated and token is not expired
      final isAuthenticated = await _authService.isAuthenticated();
      final isTokenExpired = await _authService.isTokenExpired();

      if (isAuthenticated && !isTokenExpired) {
        // User is authenticated, navigate to home
        _navigateToHome();
      } else {
        // User is not authenticated or token expired, navigate to welcome
        if (isAuthenticated && isTokenExpired) {
          // Clear expired auth data
          await _authService.clearAuthData();
        }
        _navigateToWelcome();
      }
    } catch (e) {
      // On error, clear auth data and navigate to welcome
      await _authService.clearAuthData();
      _navigateToWelcome();
    }
  }

  void _navigateToWelcome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: DesignTokens.animationNormal,
        ),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: DesignTokens.animationNormal,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: Responsive.getHorizontalPadding(context),
            child: Column(
              children: [
                // Main content centered
                Expanded(
                  child: Center(
                    child: Text(
                      'VIEW',
                      style: DesignTokens.getHeadingStyle(
                        context,
                        fontSize: Responsive.responsive<double>(
                          context,
                          mobile: 48,
                          tablet: 56,
                          desktop: 64,
                        ),
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),

                // Version Text at bottom
                Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.space4xl),
                  child: Text(
                    'Version 1.0',
                    style: DesignTokens.getCaptionStyle(
                      context,
                      fontSize: Responsive.responsive<double>(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 18,
                      ),
                      color: AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
