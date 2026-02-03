import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.curveEaseOut,
    ));

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
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
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
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
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
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: Responsive.getHorizontalPadding(context).copyWith(
              top: DesignTokens.space4xl,
              bottom: DesignTokens.space4xl,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Logo Icon with proper VIEW colors
                Container(
                  width: Responsive.responsive<double>(
                    context,
                    mobile: 120,
                    tablet: 140,
                    desktop: 160,
                  ),
                  height: Responsive.responsive<double>(
                    context,
                    mobile: 120,
                    tablet: 140,
                    desktop: 160,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.brightPurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.visibility,
                    size: Responsive.responsive<double>(
                      context,
                      mobile: 60,
                      tablet: 70,
                      desktop: 80,
                    ),
                    color: AppTheme.white,
                  ),
                ),
                
                SizedBox(height: DesignTokens.space4xl),
                
                // Welcome Text with proper styling
                Text(
                  'Welcome to VIEW',
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
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: DesignTokens.spaceLg),
                
                // Subtitle
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
                    color: AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 3),
                
                // Login Button with proper VIEW primary color
                CustomButton(
                  text: 'Log in',
                  onPressed: _navigateToLogin,
                  type: ButtonType.primary,
                  size: ButtonSize.large,
                  fullWidth: true,
                ),
                
                SizedBox(height: DesignTokens.spaceLg),
                
                // Sign up Button with outline style
                CustomButton(
                  text: 'Sign up',
                  onPressed: _navigateToRegister,
                  type: ButtonType.outline,
                  size: ButtonSize.large,
                  fullWidth: true,
                ),
                
                SizedBox(height: DesignTokens.space4xl),
                
                // Continue With Accounts Text
                Text(
                  'Continue With Accounts',
                  style: DesignTokens.getCaptionStyle(
                    context,
                    fontSize: 14,
                    color: AppTheme.lightTextSecondary,
                  ),
                ),
                
                SizedBox(height: DesignTokens.spaceLg),
                
                // Social Login Buttons with proper colors
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'GOOGLE',
                        onPressed: () {
                          // TODO: Implement Google login
                        },
                        type: ButtonType.outline,
                        size: ButtonSize.medium,
                        customColor: const Color(0xFFDB4437),
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceLg),
                    Expanded(
                      child: CustomButton(
                        text: 'FACEBOOK',
                        onPressed: () {
                          // TODO: Implement Facebook login
                        },
                        type: ButtonType.outline,
                        size: ButtonSize.medium,
                        customColor: const Color(0xFF4267B2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}