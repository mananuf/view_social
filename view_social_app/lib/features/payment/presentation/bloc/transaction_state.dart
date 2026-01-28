import 'package:equatable/equatable.dart';
import '../../../../shared/models/wallet_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionsLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final bool hasMore;
  final int currentPage;

  const TransactionsLoaded({
    required this.transactions,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object> get props => [transactions, hasMore, currentPage];

  TransactionsLoaded copyWith({
    List<TransactionModel>? transactions,
    bool? hasMore,
    int? currentPage,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TransactionLoadingMore extends TransactionState {
  final List<TransactionModel> transactions;
  final int currentPage;

  const TransactionLoadingMore({
    required this.transactions,
    required this.currentPage,
  });

  @override
  List<Object> get props => [transactions, currentPage];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}
