import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/payment_account_model.dart';
import '../../firebase_Services/notification_services.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _accounts => _firestore.collection('payment_accounts');
  CollectionReference get _transactions => _firestore.collection('transactions');

  // Create a new payment account for user
  Future<PaymentAccountModel?> createPaymentAccount({
    required String accountName,
    required String password,
    double initialBalance = 1000.0, // Default fake balance
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final accountNumber = PaymentAccountModel.generateAccountNumber();
      final accountId = '${user.uid}_account';

      final account = PaymentAccountModel(
        id: accountId,
        userId: user.uid,
        accountNumber: accountNumber,
        accountName: accountName,
        balance: initialBalance,
        currency: 'USD',
        isActive: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        password: password,
      );

      await _accounts.doc(accountId).set(account.toMap());
      return account;
    } catch (e) {
      return null;
    }
  }

  // Get user's payment account
  Future<PaymentAccountModel?> getPaymentAccount(String userId) async {
    try {
      final accountId = '${userId}_account';
      final doc = await _accounts.doc(accountId).get();

      if (doc.exists) {
        return PaymentAccountModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Transfer fake money between users
  Future<TransactionModel?> transferMoney({
    String? receiverId,
    String? receiverAccountNumber,
    required double amount,
    required String description,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get sender's account
      final senderAccount = await getPaymentAccount(user.uid);
      if (senderAccount == null) throw Exception('Sender account not found');

      // Verify password
      if (senderAccount.password != password) {
        throw Exception('Invalid password');
      }

      // Get receiver's account - either by userId or account number
      PaymentAccountModel? receiverAccount;
      if (receiverId != null) {
        receiverAccount = await getPaymentAccount(receiverId);
      } else if (receiverAccountNumber != null) {
        receiverAccount = await getPaymentAccountByNumber(receiverAccountNumber);
      }

      if (receiverAccount == null) throw Exception('Receiver account not found');

      final actualReceiverId = receiverAccount.userId;

      // Check if sender has sufficient balance
      if (senderAccount.balance < amount) {
        throw Exception('Insufficient balance');
      }

      final transactionId = TransactionModel.generateTransactionId();

      // Create transaction record
      final transaction = TransactionModel(
        id: transactionId,
        senderId: user.uid,
        receiverId: actualReceiverId,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        status: 'completed',
        transactionType: 'send',
      );

      // Update sender's balance
      final newSenderBalance = senderAccount.balance - amount;
      await _accounts.doc(senderAccount.id).update({
        'balance': newSenderBalance,
        'lastUpdated': Timestamp.now(),
      });

      // Update receiver's balance
      final newReceiverBalance = receiverAccount.balance + amount;
      await _accounts.doc(receiverAccount.id).update({
        'balance': newReceiverBalance,
        'lastUpdated': Timestamp.now(),
      });

      // Save transaction
      await _transactions.doc(transactionId).set(transaction.toMap());

      // Create corresponding receive transaction for receiver
      final receiveTransaction = TransactionModel(
        id: '${transactionId}_receive',
        senderId: user.uid,
        receiverId: actualReceiverId,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        status: 'completed',
        transactionType: 'receive',
      );
      await _transactions.doc(receiveTransaction.id).set(receiveTransaction.toMap());

      // Send notification to receiver
      try {
        final receiverDoc = await _firestore.collection('users').doc(actualReceiverId).get();
        if (receiverDoc.exists) {
          final receiverData = receiverDoc.data()!;
          final receiverToken = receiverData['fcmToken'];
          final senderName = user.displayName ?? user.email?.split('@')[0] ?? 'Someone';

          if (receiverToken != null && receiverToken.isNotEmpty) {
            await NotificationService.sendPushNotification(
              targetToken: receiverToken,
              title: '💰 Payment Received',
              body: '$senderName sent you \$${amount.toStringAsFixed(2)}${description.isNotEmpty ? ' for $description' : ''}',
              type: 'payment',
              senderId: user.uid,
              chatId: '', // No specific chat for payments
              senderName: senderName,
              callType: '',
              callId: '',
              data: {},
              payload: {
                'type': 'payment',
                'senderId': user.uid,
                'receiverId': actualReceiverId,
                'amount': amount.toString(),
                'description': description,
                'transactionId': transactionId,
              },
            );
          }
        }
      } catch (e) {
        // Don't fail the transaction if notification fails
        print('Failed to send payment notification: $e');
      }

      return transaction;
    } catch (e) {
      return null;
    }
  }

  // Get transaction history for user
  Stream<List<TransactionModel>> getTransactionHistory(String userId) {
    return _transactions
        .where('senderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  // Get all transactions (send and receive) for user
  Stream<List<TransactionModel>> getAllTransactions(String userId) {
    return _transactions
        .where(Filter.or(
          Filter('senderId', isEqualTo: userId),
          Filter('receiverId', isEqualTo: userId),
        ))
        .snapshots()
        .map((snapshot) {
          final allTransactions = snapshot.docs.map((doc) {
            return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Filter transactions based on user role and transaction type
          final filteredTransactions = allTransactions.where((transaction) {
            if (transaction.transactionType == 'send') {
              return transaction.senderId == userId;
            } else if (transaction.transactionType == 'receive') {
              return transaction.receiverId == userId;
            }
            return false;
          }).toList();

          // Sort by timestamp descending
          filteredTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return filteredTransactions;
        });
  }

  // Get payment account by account number
  Future<PaymentAccountModel?> getPaymentAccountByNumber(String accountNumber) async {
    try {
      final snapshot = await _accounts.where('accountNumber', isEqualTo: accountNumber).get();
      if (snapshot.docs.isNotEmpty) {
        return PaymentAccountModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get list of all users with payment accounts (for transfer selection)
  Future<List<PaymentAccountModel>> getAllPaymentAccounts() async {
    try {
      final snapshot = await _accounts.get();
      return snapshot.docs.map((doc) {
        return PaymentAccountModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Update account balance (for admin purposes or testing)
  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      await _accounts.doc(accountId).update({
        'balance': newBalance,
        'lastUpdated': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}