import 'package:equatable/equatable.dart';

abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

class TransferInitiated extends TransferEvent {
  final String receiverId;
  final double amount;
  final String pin;
  final String? description;

  const TransferInitiated({
    required this.receiverId,
    required this.amount,
    required this.pin,
    this.description,
  });

  @override
  List<Object?> get props => [receiverId, amount, pin, description];
}

class TransferValidationRequested extends TransferEvent {
  final String receiverId;
  final double amount;

  const TransferValidationRequested({
    required this.receiverId,
    required this.amount,
  });

  @override
  List<Object> get props => [receiverId, amount];
}

class TransferReset extends TransferEvent {
  const TransferReset();
}
