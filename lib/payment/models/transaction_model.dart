import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String status;             // pending, completed, failed
  final String transactionType;    // send, receive

  /// Generate Unique Transaction ID
  static String generateTransactionId() {
    final now = DateTime.now();
    return "TXN${now.millisecondsSinceEpoch}${now.microsecond}";
  }

  TransactionModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.transactionType,
  });

  /// Create model from Firebase Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? generateTransactionId(),
      senderId: map['senderId']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description']?.toString() ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status']?.toString() ?? 'pending',
      transactionType: map['transactionType']?.toString() ?? 'send',
    );
  }

  /// Convert to Firebase Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'transactionType': transactionType,
    };
  }

  /// Copy with updated values
  TransactionModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    double? amount,
    String? description,
    DateTime? timestamp,
    String? status,
    String? transactionType,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
    );
  }
}
