import 'package:flutter/material.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/theme/app_theme.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String _filterType = 'all'; // all, sent, received
  
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
  
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final transactions = _generateMockTransactions();
      
      setState(() {
        _transactions.clear();
        _transactions.addAll(transactions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _onRefresh() async {
    await _loadTransactions();
  }
  
  List<TransactionModel> _generateMockTransactions() {
    return List.generate(30, (index) {
      return TransactionModel(
        id: 'tx_$index',
        senderId: index % 3 == 0 ? 'current_user' : 'user_$index',
        receiverId: index % 3 == 0 ? 'user_$index' : 'current_user',
        amount: (index + 1) * 500.0,
        currency: 'NGN',
        type: index % 3 == 0 ? TransactionType.send : TransactionType.receive,
        status: _getRandomStatus(index),
        description: 'Payment for ${_getRandomDescription(index)}',
        reference: 'REF${1000 + index}',
        createdAt: DateTime.now().subtract(Duration(hours: index * 4)),
      );
    });
  }
  
  TransactionStatus _getRandomStatus(int index) {
    if (index % 10 == 0) return TransactionStatus.pending;
    if (index % 15 == 0) return TransactionStatus.failed;
    return TransactionStatus.completed;
  }
  
  String _getRandomDescription(int index) {
    final descriptions = [
      'groceries',
      'lunch',
      'transport',
      'utilities',
      'shopping',
      'entertainment',
      'subscription',
      'gift',
      'services',
      'other',
    ];
    return descriptions[index % descriptions.length];
  }
  
  List<TransactionModel> get _filteredTransactions {
    if (_filterType == 'all') return _transactions;
    
    return _transactions.where((tx) {
      if (_filterType == 'sent') {
        return tx.type == TransactionType.send;
      } else if (_filterType == 'received') {
        return tx.type == TransactionType.receive;
      }
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(theme),
          
          // Transactions List
          Expanded(
            child: _isLoading && _transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.isMobile(context) ? 16 : 24,
                            vertical: 8,
                          ),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionTile(
                              theme,
                              _filteredTransactions[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(theme, 'All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(theme, 'Sent', 'sent'),
          const SizedBox(width: 8),
          _buildFilterChip(theme, 'Received', 'received'),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(ThemeData theme, String label, String value) {
    final isSelected = _filterType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTransactionTile(ThemeData theme, TransactionModel transaction) {
    final isReceived = transaction.type == TransactionType.receive;
    
    return GestureDetector(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isReceived ? AppTheme.successColor : AppTheme.primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                color: isReceived ? AppTheme.successColor : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReceived ? 'Received Payment' : 'Sent Payment',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getFontSize(context, 15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.description ?? 'No description',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: Responsive.getFontSize(context, 13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: Responsive.getFontSize(context, 12),
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
                    fontSize: Responsive.getFontSize(context, 16),
                  ),
                ),
                const SizedBox(height: 4),
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
      ),
    );
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Transactions'),
              onTap: () {
                setState(() {
                  _filterType = 'all';
                });
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Sent Only'),
              onTap: () {
                setState(() {
                  _filterType = 'sent';
                });
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Received Only'),
              onTap: () {
                setState(() {
                  _filterType = 'received';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isReceived = transaction.type == TransactionType.receive;
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Transaction Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              _buildDetailRow(theme, 'Amount', '₦${transaction.amount.toStringAsFixed(2)}'),
              _buildDetailRow(theme, 'Type', isReceived ? 'Received' : 'Sent'),
              _buildDetailRow(theme, 'Status', transaction.status.name.toUpperCase()),
              _buildDetailRow(theme, 'Reference', transaction.reference ?? 'N/A'),
              _buildDetailRow(theme, 'Description', transaction.description ?? 'No description'),
              _buildDetailRow(theme, 'Date', _formatFullDate(transaction.createdAt)),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
  
  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}