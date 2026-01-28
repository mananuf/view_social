import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/wallet_model.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final ApiClient apiClient;

  TransactionBloc({required this.apiClient})
      : super(const TransactionInitial()) {
    on<TransactionsLoadRequested>(_onTransactionsLoadRequested);
    on<TransactionsRefreshRequested>(_onTransactionsRefreshRequested);
    on<TransactionsLoadMoreRequested>(_onTransactionsLoadMoreRequested);
  }

  Future<void> _onTransactionsLoadRequested(
    TransactionsLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final response = await apiClient.dio.get('/transactions', queryParameters: {
        'limit': AppConstants.defaultPageSize,
        'offset': 0,
      });

      final transactions = (response.data['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      final hasMore = transactions.length >= AppConstants.defaultPageSize;

      emit(TransactionsLoaded(
        transactions: transactions,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(TransactionError(_getErrorMessage(e)));
    }
  }

  Future<void> _onTransactionsRefreshRequested(
    TransactionsRefreshRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final response = await apiClient.dio.get('/transactions', queryParameters: {
        'limit': AppConstants.defaultPageSize,
        'offset': 0,
      });

      final transactions = (response.data['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      final hasMore = transactions.length >= AppConstants.defaultPageSize;

      emit(TransactionsLoaded(
        transactions: transactions,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(TransactionError(_getErrorMessage(e)));
    }
  }

  Future<void> _onTransactionsLoadMoreRequested(
    TransactionsLoadMoreRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (state is! TransactionsLoaded) return;

    final currentState = state as TransactionsLoaded;
    if (!currentState.hasMore) return;

    emit(TransactionLoadingMore(
      transactions: currentState.transactions,
      currentPage: currentState.currentPage,
    ));

    try {
      final offset = currentState.currentPage * AppConstants.defaultPageSize;
      final response = await apiClient.dio.get('/transactions', queryParameters: {
        'limit': AppConstants.defaultPageSize,
        'offset': offset,
      });

      final newTransactions = (response.data['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      final allTransactions = [
        ...currentState.transactions,
        ...newTransactions
      ];
      final hasMore = newTransactions.length >= AppConstants.defaultPageSize;

      emit(TransactionsLoaded(
        transactions: allTransactions,
        hasMore: hasMore,
        currentPage: currentState.currentPage + 1,
      ));
    } catch (e) {
      emit(currentState);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load transactions. Please try again.';
  }
}
