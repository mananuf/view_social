import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

class WalletRefreshRequested extends WalletEvent {
  const WalletRefreshRequested();
}

class WalletPinSetRequested extends WalletEvent {
  final String pin;

  const WalletPinSetRequested(this.pin);

  @override
  List<Object> get props => [pin];
}

class WalletBalanceUpdated extends WalletEvent {
  final double newBalance;

  const WalletBalanceUpdated(this.newBalance);

  @override
  List<Object> get props => [newBalance];
}
