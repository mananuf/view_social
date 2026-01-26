import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/responsive.dart';

class SendMoneyPage extends StatefulWidget {
  const SendMoneyPage({super.key});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pinController = TextEditingController();
  
  UserModel? _selectedRecipient;
  bool _isLoading = false;
  bool _showPinInput = false;
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _pinController.dispose();
    super.dispose();
  }
  
  Future<void> _selectRecipient() async {
    // TODO: Navigate to contact selection page
    // For now, use mock data
    final recipient = UserModel(
      id: 'user_1',
      username: 'johndoe',
      email: 'john@example.com',
      displayName: 'John Doe',
      avatarUrl: null,
      isVerified: true,
      followerCount: 1000,
      followingCount: 500,
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _selectedRecipient = recipient;
    });
  }
  
  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _showPinInput = true;
    });
  }
  
  Future<void> _confirmPayment() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your 4-digit PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual payment with BLoC
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(); // Go back to wallet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.getPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              // Recipient Selection
              _buildRecipientSection(theme),
              
              const SizedBox(height: 24),
              
              // Amount Input
              CustomTextField(
                label: 'Amount',
                hint: 'Enter amount',
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: Validators.validateAmount,
                prefixIcon: const Icon(Icons.money),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description Input
              CustomTextField(
                label: 'Description (Optional)',
                hint: 'What is this payment for?',
                controller: _descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.note),
              ),
              
              const SizedBox(height: 32),
              
              // PIN Input (shown after proceeding)
              if (_showPinInput) ...[
                _buildPinSection(theme),
                const SizedBox(height: 24),
              ],
              
              // Action Button
              if (!_showPinInput)
                CustomButton(
                  text: 'Proceed to Payment',
                  onPressed: _proceedToPayment,
                  fullWidth: true,
                  size: ButtonSize.large,
                  icon: const Icon(Icons.arrow_forward),
                )
              else
                CustomButton(
                  text: 'Confirm Payment',
                  onPressed: _confirmPayment,
                  isLoading: _isLoading,
                  fullWidth: true,
                  size: ButtonSize.large,
                  icon: const Icon(Icons.check),
                ),
              
              const SizedBox(height: 24),
              
              // Payment Summary
              if (_showPinInput) _buildPaymentSummary(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecipientSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: Responsive.getFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        GestureDetector(
          onTap: _selectRecipient,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: _selectedRecipient == null
                ? Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select recipient',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          _selectedRecipient!.displayName?.substring(0, 1).toUpperCase() ??
                              _selectedRecipient!.username.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _selectedRecipient!.displayName ?? _selectedRecipient!.username,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_selectedRecipient!.isVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '@${_selectedRecipient!.username}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedRecipient = null;
                          });
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPinSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter PIN',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: Responsive.getFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        CustomTextField(
          controller: _pinController,
          hint: 'Enter your 4-digit PIN',
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          prefixIcon: const Icon(Icons.lock),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPaymentSummary(ThemeData theme) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(theme, 'Amount', '₦${amount.toStringAsFixed(2)}'),
          _buildSummaryRow(theme, 'Fee', '₦0.00'),
          
          const Divider(height: 24),
          
          _buildSummaryRow(
            theme,
            'Total',
            '₦${amount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(ThemeData theme, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}