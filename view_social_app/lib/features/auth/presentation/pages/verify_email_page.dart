import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import 'home_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String verificationType;
  final String identifier;

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.verificationType,
    required this.identifier,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isResending = false;

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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _slideController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length > 1) {
      // Handle pasted content
      _handlePastedCode(value, index);
      return;
    }

    if (value.isNotEmpty) {
      // Only allow digits
      if (!RegExp(r'^\d$').hasMatch(value)) {
        _controllers[index].clear();
        return;
      }

      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    }
  }

  void _handlePastedCode(String pastedText, int startIndex) {
    // Extract only digits from pasted text
    final digits = pastedText.replaceAll(RegExp(r'[^\d]'), '');

    // Fill the controllers starting from the current index
    for (int i = 0; i < digits.length && (startIndex + i) < 6; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    // Move focus to the next empty field or verify if complete
    final nextEmptyIndex = _controllers.indexWhere(
      (controller) => controller.text.isEmpty,
    );
    if (nextEmptyIndex != -1) {
      _focusNodes[nextEmptyIndex].requestFocus();
    } else {
      _focusNodes.last.unfocus();
      _verifyCode();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    if (_verificationCode.length != 6) {
      _showSnackBar(
        'Please enter the complete verification code',
        AppTheme.warningColor,
      );
      return;
    }

    // Trigger verification event
    context.read<AuthBloc>().add(
      VerifyEvent(identifier: widget.identifier, code: _verificationCode),
    );
  }

  Future<void> _resendCode() async {
    // Trigger resend verification event
    context.read<AuthBloc>().add(
      ResendVerificationEvent(identifier: widget.identifier),
    );
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

  String get _maskedEmail {
    final identifier = widget.verificationType == 'email'
        ? widget.email
        : widget.identifier;

    if (widget.verificationType == 'phone') {
      // Mask phone number
      if (identifier.length > 4) {
        return '${identifier.substring(0, 3)}***${identifier.substring(identifier.length - 2)}';
      }
      return identifier;
    }

    // Mask email
    final parts = identifier.split('@');
    if (parts.length != 2) return identifier;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) return identifier;

    final maskedUsername = '${username.substring(0, 3)}***';
    return '$maskedUsername@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTextSecondary.withValues(alpha: 0.1),
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

            if (state is AuthSuccess) {
              // Navigate to home page on successful verification
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const HomePage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: DesignTokens.animationNormal,
                ),
                (route) => false,
              );
            } else if (state is ResendVerificationSuccess) {
              _showSnackBar(
                'Verification code sent successfully',
                AppTheme.successColor,
              );
              // Clear existing codes
              for (var controller in _controllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();
            } else if (state is AuthError) {
              _showSnackBar(state.message, AppTheme.errorColor);
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
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Center(
                    child: Container(
                      margin: Responsive.getHorizontalPadding(context),
                      padding: DesignTokens.padding3xl,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: DesignTokens.borderRadius3xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            widget.verificationType == 'email'
                                ? 'Verify Email'
                                : 'Verify Phone',
                            style: DesignTokens.getHeadingStyle(
                              context,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTextPrimary,
                            ),
                          ),

                          SizedBox(height: DesignTokens.spaceLg),

                          // Subtitle
                          Text(
                            widget.verificationType == 'email'
                                ? 'We Have Sent Code To Your Email'
                                : 'We Have Sent Code To Your Phone',
                            style: DesignTokens.getBodyStyle(
                              context,
                              fontSize: 14,
                              color: AppTheme.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: DesignTokens.space2xl),

                          // Email Display
                          Text(
                            _maskedEmail,
                            style: DesignTokens.getBodyStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.lightTextPrimary,
                            ),
                          ),

                          SizedBox(height: DesignTokens.space4xl),

                          // OTP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.lightBorderColor,
                                    width: 1.5,
                                  ),
                                  borderRadius: DesignTokens.borderRadiusLg,
                                ),
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  onChanged: (value) =>
                                      _onCodeChanged(value, index),
                                  onTap: () {
                                    _controllers[index]
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _controllers[index].text.length,
                                      ),
                                    );
                                  },
                                  onSubmitted: (value) {
                                    if (value.isEmpty && index > 0) {
                                      _onBackspace(index);
                                    }
                                  },
                                ),
                              );
                            }),
                          ),

                          SizedBox(height: DesignTokens.space4xl),

                          // Verify Button
                          CustomButton(
                            text: 'Verify',
                            onPressed: _verifyCode,
                            isLoading: _isLoading,
                            fullWidth: true,
                            size: ButtonSize.large,
                            useGradient: true,
                          ),

                          SizedBox(height: DesignTokens.spaceLg),

                          // Send Again Button
                          CustomButton(
                            text: 'Send Again',
                            onPressed: _resendCode,
                            isLoading: _isResending,
                            type: ButtonType.ghost,
                            fullWidth: true,
                            size: ButtonSize.medium,
                            customColor: AppTheme.lightTextSecondary,
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
      ),
    );
  }
}
