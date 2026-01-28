import 'package:equatable/equatable.dart';
import '../../../../shared/models/wallet_model.dart';

abstract class TransferState extends Equatable {
  const TransferState();

  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {
  const TransferInitial();
}

class TransferValidating extends TransferState {
  const TransferValidating();
}

class TransferValidated extends TransferState {
  final String receiverId;
  final String receiverName;
  final double amount;
  final bool hasSufficientFunds;

  const TransferValidated({
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    required this.hasSufficientFunds,
  });

  @override
  List<Object> get props => [
        receiverId,
        receiverName,
        amount,
        hasSufficientFunds,
      ];
}

class TransferProcessing extends TransferState {
  const TransferProcessing();
}

class TransferSuccess extends TransferState {
  final TransactionModel transaction;

  const TransferSuccess(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class TransferError extends TransferState {
  final String message;

  const TransferError(this.message);

  @override
  List<Object> get props => [message];
}
