import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'forgot_password_page.dart';

class VerifyPhonePage extends StatefulWidget {
  final String phoneNumber;

  const VerifyPhonePage({super.key, required this.phoneNumber});

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage>
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

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual verification logic with BLoC
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ForgotPasswordPage(),
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
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Verification failed: ${e.toString()}',
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

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      // TODO: Implement actual resend logic with BLoC
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        _showSnackBar(
          'Verification code sent successfully',
          AppTheme.successColor,
        );
        // Clear existing codes
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Failed to resend code: ${e.toString()}',
          AppTheme.errorColor,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
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

  String get _maskedPhoneNumber {
    if (widget.phoneNumber.length <= 4) return widget.phoneNumber;

    final visiblePart = widget.phoneNumber.substring(
      widget.phoneNumber.length - 4,
    );
    final maskedPart = '*' * (widget.phoneNumber.length - 4);
    return '$maskedPart$visiblePart';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTextSecondary.withValues(alpha: 0.1),
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
                          'Verify Phone',
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
                          'We Have Sent Code To Your Phone',
                          style: DesignTokens.getBodyStyle(
                            context,
                            fontSize: 14,
                            color: AppTheme.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: DesignTokens.space2xl),

                        // Phone Display
                        Text(
                          _maskedPhoneNumber,
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
    );
  }
}
