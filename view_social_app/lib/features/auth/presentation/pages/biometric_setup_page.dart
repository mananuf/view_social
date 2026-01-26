import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/theme/responsive.dart';

class BiometricSetupPage extends StatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  State<BiometricSetupPage> createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends State<BiometricSetupPage> {
  final _localAuth = LocalAuthentication();
  
  bool _isLoading = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  
  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }
  
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _biometricAvailable = isAvailable && isDeviceSupported;
        _availableBiometrics = availableBiometrics;
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
        _availableBiometrics = [];
      });
    }
  }
  
  Future<void> _setupBiometric() async {
    if (!_biometricAvailable) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated && mounted) {
        // TODO: Save biometric preference to local storage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup biometric: ${e.toString()}'),
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
  
  void _skipSetup() {
    Navigator.of(context).pop(false); // Return skipped
  }
  
  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }
  
  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.getPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Biometric Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _biometricAvailable 
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        _biometricAvailable ? _getBiometricIcon() : Icons.error_outline,
                        size: 60,
                        color: _biometricAvailable 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      _biometricAvailable 
                          ? 'Enable ${_getBiometricTypeText()}'
                          : 'Biometric Not Available',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: Responsive.getFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      _biometricAvailable
                          ? 'Use your ${_getBiometricTypeText().toLowerCase()} to quickly and securely access your VIEW Social account.'
                          : 'Your device does not support biometric authentication or it is not set up.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: Responsive.getFontSize(context, 16),
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Benefits List
                    if (_biometricAvailable) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildBenefitItem(
                              context,
                              Icons.speed,
                              'Quick Access',
                              'Login instantly without typing passwords',
                            ),
                            const SizedBox(height: 16),
                            _buildBenefitItem(
                              context,
                              Icons.security,
                              'Enhanced Security',
                              'Your biometric data stays on your device',
                            ),
                            const SizedBox(height: 16),
                            _buildBenefitItem(
                              context,
                              Icons.privacy_tip,
                              'Privacy Protected',
                              'No biometric data is sent to our servers',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_biometricAvailable) ...[
                    CustomButton(
                      text: 'Enable ${_getBiometricTypeText()}',
                      onPressed: _setupBiometric,
                      isLoading: _isLoading,
                      fullWidth: true,
                      size: ButtonSize.large,
                      icon: Icon(_getBiometricIcon()),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    CustomButton(
                      text: 'Skip for Now',
                      onPressed: _skipSetup,
                      type: ButtonType.text,
                      fullWidth: true,
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'Continue',
                      onPressed: _skipSetup,
                      fullWidth: true,
                      size: ButtonSize.large,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: Responsive.getFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: Responsive.getFontSize(context, 12),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}