import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_account_model.dart';
import '../models/transaction_model.dart';
import '../services/payment_service.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables
  var isLoading = false.obs;
  var paymentAccount = Rx<PaymentAccountModel?>(null);
  var transactions = <TransactionModel>[].obs;
  var allPaymentAccounts = <PaymentAccountModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPaymentAccount();
    loadTransactions();
    loadAllPaymentAccounts();
  }

  // Load user's payment account
  Future<void> loadPaymentAccount() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user != null) {
        paymentAccount.value = await _paymentService.getPaymentAccount(user.uid);
      }
    } catch (e) {
      // Error loading payment account
    } finally {
      // Add a small delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 100));
      isLoading.value = false;
    }
  }

  // Create new payment account
  Future<bool> createPaymentAccount(String accountName, String password) async {
    try {
      isLoading.value = true;
      final account = await _paymentService.createPaymentAccount(
        accountName: accountName,
        password: password,
      );
      if (account != null) {
        paymentAccount.value = account;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      // Add a small delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 100));
      isLoading.value = false;
    }
  }

  // Transfer money to another user
  Future<TransactionModel?> transferMoney(String receiverId, double amount, String description, String password) async {
    return await transferMoneyById(receiverId, amount, description, password);
  }

  // Transfer money by account number
  Future<TransactionModel?> transferMoneyByAccountNumber(String accountNumber, double amount, String description, String password) async {
    return await _transferMoney(null, accountNumber, amount, description, password);
  }

  // Transfer money by user ID
  Future<TransactionModel?> transferMoneyById(String receiverId, double amount, String description, String password) async {
    return await _transferMoney(receiverId, null, amount, description, password);
  }

  Future<TransactionModel?> _transferMoney(String? receiverId, String? accountNumber, double amount, String description, String password) async {
    try {
      isLoading.value = true;
      final transaction = await _paymentService.transferMoney(
        receiverId: receiverId,
        receiverAccountNumber: accountNumber,
        amount: amount,
        description: description,
        password: password,
      );

      if (transaction != null) {
        // Refresh account balance and transactions
        await loadPaymentAccount();
        loadTransactions();
        return transaction;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      // Add a small delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 100));
      isLoading.value = false;
    }
  }

  // Load transaction history
  void loadTransactions() {
    final user = _auth.currentUser;
    if (user != null) {
      _paymentService.getAllTransactions(user.uid).listen((transactionList) {
        transactions.value = transactionList;
      });
    }
  }

  // Load all payment accounts (for transfer selection)
  Future<void> loadAllPaymentAccounts() async {
    try {
      allPaymentAccounts.value = await _paymentService.getAllPaymentAccounts();
    } catch (e) {
      // Error loading payment accounts
    }
  }

  // Get available receivers (excluding current user)
  List<PaymentAccountModel> getAvailableReceivers() {
    final user = _auth.currentUser;
    if (user == null) return [];

    return allPaymentAccounts.where((account) => account.userId != user.uid).toList();
  }

  // Check if user has payment account
  bool get hasPaymentAccount => paymentAccount.value != null;

  // Get current balance
  double get currentBalance => paymentAccount.value?.balance ?? 0.0;

  // Get account number
  String get accountNumber => paymentAccount.value?.accountNumber ?? '';

  // Get account name
  String get accountName => paymentAccount.value?.accountName ?? '';
}