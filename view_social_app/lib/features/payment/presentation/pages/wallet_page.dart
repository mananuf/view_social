import 'package:flutter/material.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import 'send_money_page.dart';
import 'transaction_history_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  WalletModel? _wallet;
  bool _isLoading = false;
  bool _balanceVisible = true;
  
  @override
  void initState() {
    super.initState();
    _loadWallet();
  }
  
  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final wallet = WalletModel(
        id: 'wallet_1',
        userId: 'current_user',
        balance: 25000.50,
        currency: 'NGN',
        status: WalletStatus.active,
        hasPinSet: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _toggleBalanceVisibility() {
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
  }
  
  void _navigateToSendMoney() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SendMoneyPage(),
      ),
    );
  }
  
  void _navigateToTransactionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryPage(),
      ),
    );
  }
  
  void _setupPin() {
    // TODO: Navigate to PIN setup page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN setup coming soon!'),
      ),
    );
  }
  
  void _addMoney() {
    // TODO: Navigate to add money page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add money feature coming soon!'),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.getPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIEWpay Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToTransactionHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to wallet settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Balance Card
                    _buildBalanceCard(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(theme),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Transactions
                    _buildRecentTransactions(theme),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildBalanceCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: Responsive.getFontSize(context, 14),
                ),
              ),
              IconButton(
                icon: Icon(
                  _balanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _toggleBalanceVisibility,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _balanceVisible
                ? '₦${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}'
                : '₦••••••',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.getFontSize(context, 36),
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _wallet?.status.name.toUpperCase() ?? 'UNKNOWN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!(_wallet?.hasPinSet ?? false))
                TextButton.icon(
                  onPressed: _setupPin,
                  icon: const Icon(Icons.lock_outline, color: Colors.white, size: 16),
                  label: const Text(
                    'Setup PIN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            theme,
            Icons.send,
            'Send Money',
            AppTheme.primaryColor,
            _navigateToSendMoney,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            theme,
            Icons.add,
            'Add Money',
            AppTheme.successColor,
            _addMoney,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: Responsive.getFontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentTransactions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: Responsive.getFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToTransactionHistory,
              child: const Text('See All'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Mock transactions
        ..._generateMockTransactions().map((transaction) {
          return _buildTransactionTile(theme, transaction);
        }),
      ],
    );
  }
  
  Widget _buildTransactionTile(ThemeData theme, TransactionModel transaction) {
    final isReceived = transaction.type == TransactionType.receive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isReceived ? AppTheme.successColor : AppTheme.primaryColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isReceived ? Icons.arrow_downward : Icons.arrow_upward,
              color: isReceived ? AppTheme.successColor : AppTheme.primaryColor,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceived ? 'Received from User' : 'Sent to User',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(transaction.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isReceived ? '+' : '-'}₦${transaction.amount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isReceived ? AppTheme.successColor : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(transaction.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  List<TransactionModel> _generateMockTransactions() {
    return List.generate(5, (index) {
      return TransactionModel(
        id: 'tx_$index',
        senderId: index % 2 == 0 ? 'current_user' : 'user_$index',
        receiverId: index % 2 == 0 ? 'user_$index' : 'current_user',
        amount: (index + 1) * 1000.0,
        currency: 'NGN',
        type: index % 2 == 0 ? TransactionType.send : TransactionType.receive,
        status: TransactionStatus.completed,
        description: 'Payment ${index + 1}',
        reference: 'REF${index + 1}',
        createdAt: DateTime.now().subtract(Duration(hours: index * 6)),
      );
    });
  }
  
  IconData _getStatusIcon() {
    switch (_wallet?.status) {
      case WalletStatus.active:
        return Icons.check_circle;
      case WalletStatus.suspended:
        return Icons.pause_circle;
      case WalletStatus.locked:
        return Icons.lock;
      default:
        return Icons.help;
    }
  }
  
  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppTheme.paymentSuccessColor;
      case TransactionStatus.pending:
        return AppTheme.paymentPendingColor;
      case TransactionStatus.failed:
        return AppTheme.paymentFailedColor;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}