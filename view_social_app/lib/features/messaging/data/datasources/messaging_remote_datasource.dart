import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_routes.dart';
import '../../../../shared/models/user_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class MessagingRemoteDataSource {
  Future<List<UserModel>> searchUsers(String query);
  Future<ConversationModel> createConversation(
    List<String> participantIds, {
    bool isGroup = false,
    String? groupName,
  });
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
  });
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
  });
  Future<void> markMessageAsRead(String conversationId, String messageId);
  Future<void> sendTypingIndicator(String conversationId, bool isTyping);
}

class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final ApiClient apiClient;

  MessagingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiRoutes.searchUsers}?q=$query',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to search users',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiRoutes.searchUsers),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<ConversationModel> createConversation(
    List<String> participantIds, {
    bool isGroup = false,
    String? groupName,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiRoutes.conversations,
        data: {
          'participant_ids': participantIds,
          'is_group': isGroup,
          if (groupName != null) 'group_name': groupName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        return ConversationModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to create conversation',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiRoutes.conversations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await apiClient.dio.get(ApiRoutes.conversations);

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map(
              (json) =>
                  ConversationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to get conversations',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiRoutes.conversations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        ApiRoutes.conversationMessages(conversationId),
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to get messages',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ApiRoutes.conversationMessages(conversationId),
        ),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiRoutes.conversationMessages(conversationId),
        data: {'content': content, 'message_type': messageType},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        return MessageModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to send message',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ApiRoutes.conversationMessages(conversationId),
        ),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<void> markMessageAsRead(
    String conversationId,
    String messageId,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiRoutes.conversationRead(conversationId),
        data: {'message_id': messageId},
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to mark message as read',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ApiRoutes.conversationRead(conversationId),
        ),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      final response = await apiClient.dio.post(
        ApiRoutes.conversationTyping(conversationId),
        data: {'is_typing': isTyping},
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to send typing indicator',
        );
      }
    } on DioException {
      // Silently fail for typing indicators - not critical
    } catch (e) {
      // Silently fail for typing indicators - not critical
    }
  }
}
