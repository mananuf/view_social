import 'package:equatable/equatable.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionsLoadRequested extends TransactionEvent {
  const TransactionsLoadRequested();
}

class TransactionsRefreshRequested extends TransactionEvent {
  const TransactionsRefreshRequested();
}

class TransactionsLoadMoreRequested extends TransactionEvent {
  const TransactionsLoadMoreRequested();
}
