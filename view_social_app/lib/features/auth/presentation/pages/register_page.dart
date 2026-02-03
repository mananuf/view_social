import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/theme/responsive.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

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
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
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
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine if it's email or phone registration
    final identifier = _emailController.text.trim();
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

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
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
      backgroundColor: AppTheme.lightBackgroundColor,
      body: SafeArea(
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
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      VerifyEmailPage(
                        email: _emailController.text,
                        verificationType: state.response.verificationType,
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
                          SizedBox(height: DesignTokens.spaceLg),

                          // Title with blue underlines (matching Figma design)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create your',
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
                              Row(
                                children: [
                                  Text(
                                    'Account',
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
                                  SizedBox(width: DesignTokens.spaceSm),
                                  // Blue underline decoration
                                  Container(
                                    height: 3,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.infoColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

                          // Email Field
                          CustomTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.validateEmail,
                            prefixIcon: Icon(
                              Icons.email_outlined,
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

                          // Register Button with gradient
                          CustomButton(
                            text: 'Register',
                            onPressed: _handleRegister,
                            isLoading: _isLoading,
                            fullWidth: true,
                            size: ButtonSize.large,
                            useGradient: true,
                          ),

                          SizedBox(height: DesignTokens.space2xl),

                          // Login Link
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already Have An Account? ',
                                  style: DesignTokens.getBodyStyle(
                                    context,
                                    fontSize: 14,
                                    color: AppTheme.lightTextSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _navigateToLogin,
                                  child: Text(
                                    'Sign In',
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

                          SizedBox(height: DesignTokens.space4xl),

                          // Continue With Accounts Text
                          Center(
                            child: Text(
                              'Continue With Accounts',
                              style: DesignTokens.getCaptionStyle(
                                context,
                                fontSize: 14,
                                color: AppTheme.lightTextSecondary,
                              ),
                            ),
                          ),

                          SizedBox(height: DesignTokens.spaceLg),

                          // Social Login Buttons
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'GOOGLE',
                                  onPressed: () {
                                    // TODO: Implement Google registration
                                  },
                                  type: ButtonType.outline,
                                  size: ButtonSize.medium,
                                  customColor: const Color(0xFFDB4437),
                                  useGradient: false,
                                ),
                              ),
                              SizedBox(width: DesignTokens.spaceLg),
                              Expanded(
                                child: CustomButton(
                                  text: 'FACEBOOK',
                                  onPressed: () {
                                    // TODO: Implement Facebook registration
                                  },
                                  type: ButtonType.outline,
                                  size: ButtonSize.medium,
                                  customColor: const Color(0xFF4267B2),
                                  useGradient: false,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: DesignTokens.space4xl),
                        ],
                      ),
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
