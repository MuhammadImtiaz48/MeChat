import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentAccountModel {
  final String id;
  final String userId;
  final String accountNumber;
  final String accountName;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String password; // Added password field

  PaymentAccountModel({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.accountName,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.lastUpdated,
    required this.password,
  });

  factory PaymentAccountModel.fromMap(Map<String, dynamic> map) {
    return PaymentAccountModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountName: map['accountName'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'password': password,
    };
  }

  PaymentAccountModel copyWith({
    String? id,
    String? userId,
    String? accountNumber,
    String? accountName,
    double? balance,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? password,
  }) {
    return PaymentAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      password: password ?? this.password,
    );
  }

  // Generate a random account number
  static String generateAccountNumber() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'ACC${random.substring(random.length - 8)}';
  }
}