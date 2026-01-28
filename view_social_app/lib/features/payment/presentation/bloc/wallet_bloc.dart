import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../shared/models/wallet_model.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final ApiClient apiClient;
  final WebSocketClient webSocketClient;
  StreamSubscription? _wsSubscription;

  WalletBloc({
    required this.apiClient,
    required this.webSocketClient,
  }) : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onWalletLoadRequested);
    on<WalletRefreshRequested>(_onWalletRefreshRequested);
    on<WalletPinSetRequested>(_onWalletPinSetRequested);
    on<WalletBalanceUpdated>(_onWalletBalanceUpdated);

    // Subscribe to WebSocket for real-time balance updates
    _wsSubscription = webSocketClient.messageStream.listen((data) {
      if (data['type'] == 'payment_received' || data['type'] == 'payment_sent') {
        add(const WalletRefreshRequested());
      }
    });
  }

  Future<void> _onWalletLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    try {
      final response = await apiClient.dio.get('/wallet');
      final wallet = WalletModel.fromJson(response.data);
      emit(WalletLoaded(wallet));
    } catch (e) {
      emit(WalletError(_getErrorMessage(e)));
    }
  }

  Future<void> _onWalletRefreshRequested(
    WalletRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    try {
      final response = await apiClient.dio.get('/wallet');
      final wallet = WalletModel.fromJson(response.data);
      emit(WalletLoaded(wallet));
    } catch (e) {
      // Silently fail on refresh
      if (state is! WalletLoaded) {
        emit(WalletError(_getErrorMessage(e)));
      }
    }
  }

  Future<void> _onWalletPinSetRequested(
    WalletPinSetRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    try {
      await apiClient.dio.post('/wallet/pin', data: {
        'pin': event.pin,
      });
      emit(const WalletPinSetSuccess());
      // Reload wallet to get updated state
      add(const WalletLoadRequested());
    } catch (e) {
      emit(WalletError(_getErrorMessage(e)));
    }
  }

  void _onWalletBalanceUpdated(
    WalletBalanceUpdated event,
    Emitter<WalletState> emit,
  ) {
    if (state is WalletLoaded) {
      final currentState = state as WalletLoaded;
      final updatedWallet = currentState.wallet.copyWith(
        balance: event.newBalance,
      );
      emit(WalletLoaded(updatedWallet));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load wallet. Please try again.';
  }
}
