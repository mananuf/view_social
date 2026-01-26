import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum MessageType { text, image, video, voice, payment, system }

class PaymentData extends Equatable {
  final String transactionId;
  final double amount;
  final String currency;
  final String status;
  
  const PaymentData({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
  });
  
  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      transactionId: json['transaction_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'amount': amount,
      'currency': currency,
      'status': status,
    };
  }
  
  @override
  List<Object> get props => [transactionId, amount, currency, status];
}

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String? senderId;
  final UserModel? sender;
  final MessageType messageType;
  final String? content;
  final String? mediaUrl;
  final PaymentData? paymentData;
  final String? replyToId;
  final MessageModel? replyToMessage;
  final bool isRead;
  final DateTime createdAt;
  
  const MessageModel({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.sender,
    required this.messageType,
    this.content,
    this.mediaUrl,
    this.paymentData,
    this.replyToId,
    this.replyToMessage,
    required this.isRead,
    required this.createdAt,
  });
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String?,
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      paymentData: json['payment_data'] != null
          ? PaymentData.fromJson(json['payment_data'])
          : null,
      replyToId: json['reply_to_id'] as String?,
      replyToMessage: json['reply_to_message'] != null
          ? MessageModel.fromJson(json['reply_to_message'])
          : null,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender': sender?.toJson(),
      'message_type': messageType.name,
      'content': content,
      'media_url': mediaUrl,
      'payment_data': paymentData?.toJson(),
      'reply_to_id': replyToId,
      'reply_to_message': replyToMessage?.toJson(),
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    UserModel? sender,
    MessageType? messageType,
    String? content,
    String? mediaUrl,
    PaymentData? paymentData,
    String? replyToId,
    MessageModel? replyToMessage,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      paymentData: paymentData ?? this.paymentData,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        sender,
        messageType,
        content,
        mediaUrl,
        paymentData,
        replyToId,
        replyToMessage,
        isRead,
        createdAt,
      ];
}