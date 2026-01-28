import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ApiClient apiClient;

  ConversationBloc({required this.apiClient})
      : super(const ConversationInitial()) {
    on<ConversationsLoadRequested>(_onConversationsLoadRequested);
    on<ConversationCreateRequested>(_onConversationCreateRequested);
    on<ConversationUpdated>(_onConversationUpdated);
  }

  Future<void> _onConversationsLoadRequested(
    ConversationsLoadRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(const ConversationLoading());
    try {
      final response = await apiClient.dio.get('/conversations');

      final conversations = (response.data['conversations'] as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(ConversationError(_getErrorMessage(e)));
    }
  }

  Future<void> _onConversationCreateRequested(
    ConversationCreateRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(const ConversationLoading());
    try {
      final response = await apiClient.dio.post('/conversations', data: {
        'participant_ids': event.participantIds,
        if (event.groupName != null) 'group_name': event.groupName,
      });

      final conversation = ConversationModel.fromJson(response.data);
      emit(ConversationCreated(conversation));
    } catch (e) {
      emit(ConversationError(_getErrorMessage(e)));
    }
  }

  void _onConversationUpdated(
    ConversationUpdated event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationsLoaded) {
      final currentState = state as ConversationsLoaded;
      final updatedConversations = currentState.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return conv.copyWith(
            lastMessageContent:
                event.updates['last_message_content'] as String?,
            lastMessageAt: event.updates['last_message_at'] != null
                ? DateTime.parse(event.updates['last_message_at'] as String)
                : null,
            unreadCount: event.updates['unread_count'] as int? ?? conv.unreadCount,
          );
        }
        return conv;
      }).toList();

      emit(ConversationsLoaded(updatedConversations));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load conversations. Please try again.';
  }
}
