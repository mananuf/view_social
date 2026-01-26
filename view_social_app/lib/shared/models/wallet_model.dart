import 'package:equatable/equatable.dart';

enum WalletStatus { active, suspended, locked }
enum TransactionStatus { pending, completed, failed, cancelled }
enum TransactionType { send, receive, topup, withdrawal }

class WalletModel extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final WalletStatus status;
  final bool hasPinSet;
  final DateTime createdAt;
  
  const WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.status,
    required this.hasPinSet,
    required this.createdAt,
  });
  
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      status: WalletStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WalletStatus.active,
      ),
      hasPinSet: json['has_pin_set'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'status': status.name,
      'has_pin_set': hasPinSet,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    String? currency,
    WalletStatus? status,
    bool? hasPinSet,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object> get props => [
        id,
        userId,
        balance,
        currency,
        status,
        hasPinSet,
        createdAt,
      ];
}

class TransactionModel extends Equatable {
  final String id;
  final String? senderId;
  final String? receiverId;
  final double amount;
  final String currency;
  final TransactionType type;
  final TransactionStatus status;
  final String? description;
  final String? reference;
  final DateTime createdAt;
  
  const TransactionModel({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.description,
    this.reference,
    required this.createdAt,
  });
  
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.send,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: json['description'] as String?,
      reference: json['reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'status': status.name,
      'description': description,
      'reference': reference,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  TransactionModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    double? amount,
    String? currency,
    TransactionType? type,
    TransactionStatus? status,
    String? description,
    String? reference,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        amount,
        currency,
        type,
        status,
        description,
        reference,
        createdAt,
      ];
}