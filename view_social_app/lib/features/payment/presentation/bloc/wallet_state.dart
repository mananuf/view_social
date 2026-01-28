import 'package:equatable/equatable.dart';
import '../../../../shared/models/wallet_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final WalletModel wallet;

  const WalletLoaded(this.wallet);

  @override
  List<Object> get props => [wallet];

  WalletLoaded copyWith({
    WalletModel? wallet,
  }) {
    return WalletLoaded(wallet ?? this.wallet);
  }
}

class WalletPinSetSuccess extends WalletState {
  const WalletPinSetSuccess();
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object> get props => [message];
}
