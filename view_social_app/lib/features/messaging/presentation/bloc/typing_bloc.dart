import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/websocket_client.dart';
import 'typing_event.dart';
import 'typing_state.dart';

class TypingBloc extends Bloc<TypingEvent, TypingState> {
  final WebSocketClient webSocketClient;
  StreamSubscription? _wsSubscription;
  final Map<String, Timer> _typingTimers = {};

  TypingBloc({required this.webSocketClient})
      : super(const TypingIndicatorState({})) {
    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);
    on<TypingIndicatorReceived>(_onTypingIndicatorReceived);

    // Subscribe to WebSocket typing indicators
    _wsSubscription = webSocketClient.messageStream.listen((data) {
      if (data['type'] == 'typing_started') {
        add(TypingIndicatorReceived(
          conversationId: data['conversation_id'] as String,
          userId: data['user_id'] as String,
          isTyping: true,
        ));
      } else if (data['type'] == 'typing_stopped') {
        add(TypingIndicatorReceived(
          conversationId: data['conversation_id'] as String,
          userId: data['user_id'] as String,
          isTyping: false,
        ));
      }
    });
  }

  void _onTypingStarted(
    TypingStarted event,
    Emitter<TypingState> emit,
  ) {
    // Send typing indicator via WebSocket
    webSocketClient.sendMessage({
      'type': 'typing_started',
      'conversation_id': event.conversationId,
    });

    // Cancel existing timer for this conversation
    _typingTimers[event.conversationId]?.cancel();

    // Auto-stop typing after 3 seconds of inactivity
    _typingTimers[event.conversationId] = Timer(
      const Duration(seconds: 3),
      () => add(TypingStopped(event.conversationId)),
    );
  }

  void _onTypingStopped(
    TypingStopped event,
    Emitter<TypingState> emit,
  ) {
    // Send typing stopped via WebSocket
    webSocketClient.sendMessage({
      'type': 'typing_stopped',
      'conversation_id': event.conversationId,
    });

    // Cancel timer
    _typingTimers[event.conversationId]?.cancel();
    _typingTimers.remove(event.conversationId);
  }

  void _onTypingIndicatorReceived(
    TypingIndicatorReceived event,
    Emitter<TypingState> emit,
  ) {
    if (state is TypingIndicatorState) {
      final currentState = state as TypingIndicatorState;
      final updatedTypingUsers = Map<String, Set<String>>.from(
        currentState.typingUsers,
      );

      if (event.isTyping) {
        // Add user to typing set
        updatedTypingUsers[event.conversationId] ??= {};
        updatedTypingUsers[event.conversationId]!.add(event.userId);
      } else {
        // Remove user from typing set
        updatedTypingUsers[event.conversationId]?.remove(event.userId);
        if (updatedTypingUsers[event.conversationId]?.isEmpty ?? false) {
          updatedTypingUsers.remove(event.conversationId);
        }
      }

      emit(TypingIndicatorState(updatedTypingUsers));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    for (var timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    return super.close();
  }
}
