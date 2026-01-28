import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/wallet_model.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final ApiClient apiClient;

  TransferBloc({required this.apiClient}) : super(const TransferInitial()) {
    on<TransferValidationRequested>(_onTransferValidationRequested);
    on<TransferInitiated>(_onTransferInitiated);
    on<TransferReset>(_onTransferReset);
  }

  Future<void> _onTransferValidationRequested(
    TransferValidationRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferValidating());
    try {
      // Get receiver info
      final userResponse = await apiClient.dio.get('/users/${event.receiverId}');
      final receiverName = userResponse.data['display_name'] ??
          userResponse.data['username'];

      // Get current wallet balance
      final walletResponse = await apiClient.dio.get('/wallet');
      final currentBalance = (walletResponse.data['balance'] as num).toDouble();
      final hasSufficientFunds = currentBalance >= event.amount;

      emit(TransferValidated(
        receiverId: event.receiverId,
        receiverName: receiverName,
        amount: event.amount,
        hasSufficientFunds: hasSufficientFunds,
      ));
    } catch (e) {
      emit(TransferError(_getErrorMessage(e)));
    }
  }

  Future<void> _onTransferInitiated(
    TransferInitiated event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferProcessing());
    try {
      final response = await apiClient.dio.post('/transfers', data: {
        'receiver_id': event.receiverId,
        'amount': event.amount,
        'pin': event.pin,
        if (event.description != null) 'description': event.description,
      });

      final transaction = TransactionModel.fromJson(response.data);
      emit(TransferSuccess(transaction));
    } catch (e) {
      emit(TransferError(_getErrorMessage(e)));
    }
  }

  void _onTransferReset(
    TransferReset event,
    Emitter<TransferState> emit,
  ) {
    emit(const TransferInitial());
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      final statusCode = error.toString().contains('403') ? 403 : 0;
      if (statusCode == 403) {
        return 'Insufficient funds or invalid PIN.';
      }
      return 'Network error. Please check your connection.';
    }
    return 'Transfer failed. Please try again.';
  }
}
