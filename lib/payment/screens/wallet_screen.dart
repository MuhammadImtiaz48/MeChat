import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_account_model.dart';
import '../models/transaction_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PaymentController controller = Get.put(PaymentController());
  bool _hideBalance = true;
  bool _hideAccountNumber = true;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadPaymentAccount();
      controller.loadTransactions();
      controller.loadAllPaymentAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 0,
        title: Text(
          'My Wallet',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showTransferDialog(context, controller),
            tooltip: 'Send Money',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!controller.hasPaymentAccount) {
            return _buildNoAccountView(controller);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(controller),
                SizedBox(height: 24.h),
                _buildQuickActions(controller),
                SizedBox(height: 24.h),
                _buildTransactionHistory(controller),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNoAccountView(PaymentController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No Payment Account',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF075E54),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create a payment account to start sending and receiving money',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 200.w,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/payment_register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF075E54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(PaymentController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075E54), Color(0xFF128C7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24.w,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  _hideBalance ? '****' : '\$${controller.currentBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _hideBalance ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 24.w,
                ),
                onPressed: () => setState(() => _hideBalance = !_hideBalance),
                tooltip: _hideBalance ? 'Show Balance' : 'Hide Balance',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Name',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    controller.accountName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Account Number',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _hideAccountNumber
                                ? (controller.accountNumber.isNotEmpty
                                    ? '****${controller.accountNumber.substring(controller.accountNumber.length - 4)}'
                                    : 'N/A')
                                : controller.accountNumber,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        IconButton(
                          icon: Icon(
                            _hideAccountNumber ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                            size: 16.w,
                          ),
                          onPressed: () => setState(() => _hideAccountNumber = !_hideAccountNumber),
                          tooltip: _hideAccountNumber ? 'Show Account Number' : 'Hide Account Number',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  
}

  Widget _buildQuickActions(PaymentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF075E54),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.send,
                label: 'Send Money',
                color: const Color(0xFF25D366),
                onTap: () => _showTransferDialog(Get.context!, controller),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: 'Transaction History',
                color: const Color(0xFF075E54),
                onTap: () => _showTransactionHistory(Get.context!, controller),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4.r,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.w),
            SizedBox(height: 8.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      )
    );
    }

  Widget _buildTransactionHistory(PaymentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF075E54),
              ),
            ),
            TextButton(
              onPressed: () => _showTransactionHistory(Get.context!, controller),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: const Color(0xFF075E54),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(() {
          if (controller.transactions.isEmpty) {
            return Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'No transactions yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            );
          }

          // FIX: Added constrained box to give the ListView a finite height
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 300.h, // Set a maximum height for the transaction list
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.transactions.length > 5 ? 5 : controller.transactions.length,
              itemBuilder: (context, index) {
                final transaction = controller.transactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final controller = Get.find<PaymentController>();
    final isSent = transaction.transactionType == 'send';
    final amountColor = isSent ? Colors.red : Colors.green;

    // Find the counterparty name
    final counterpartyId = isSent ? transaction.receiverId : transaction.senderId;
    final counterpartyAccount = controller.allPaymentAccounts.firstWhere(
      (account) => account.userId == counterpartyId,
      orElse: () => PaymentAccountModel(
        id: '',
        userId: counterpartyId,
        accountNumber: '',
        accountName: 'Unknown User',
        balance: 0.0,
        currency: 'USD',
        isActive: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        password: '',
      ),
    );
    final counterpartyName = counterpartyAccount.accountName;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSent ? Icons.arrow_upward : Icons.arrow_downward,
              color: amountColor,
              size: 16.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isNotEmpty ? transaction.description : 'Money Transfer',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF075E54),
                  ),
                ),
                Text(
                  '${isSent ? 'To: ' : 'From: '}$counterpartyName',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(transaction.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isSent ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionSuccessDialog(TransactionModel transaction, PaymentController controller) {
    // Find the receiver's name
    final receiverAccount = controller.allPaymentAccounts.firstWhere(
      (account) => account.userId == transaction.receiverId,
      orElse: () => PaymentAccountModel(
        id: '',
        userId: transaction.receiverId,
        accountNumber: '',
        accountName: 'Unknown User',
        balance: 0.0,
        currency: 'USD',
        isActive: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        password: '',
      ),
    );

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10.r,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: RepaintBoundary(
            key: _receiptKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40.w,
                  ),
                ),
                SizedBox(height: 16.h),

                // Success Message
                Text(
                  'Transaction Successful!',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF075E54),
                  ),
                ),
                SizedBox(height: 20.h),

                // Transaction Details
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE5DD),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Amount', '\$${transaction.amount.toStringAsFixed(2)}'),
                      SizedBox(height: 8.h),
                      _buildDetailRow('To', receiverAccount.accountName),
                      SizedBox(height: 8.h),
                      _buildDetailRow('Time', DateFormat('MMM dd, yyyy HH:mm').format(transaction.timestamp)),
                      SizedBox(height: 8.h),
                      _buildDetailRow('Transaction ID', transaction.id.substring(0, 8) + '...'),
                      if (transaction.description.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        _buildDetailRow('Description', transaction.description),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _saveReceipt(),
                        icon: Icon(Icons.download, size: 20.w),
                        label: Text('Save', style: GoogleFonts.poppins()),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: const BorderSide(color: Color(0xFF075E54)),
                          foregroundColor: const Color(0xFF075E54),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareReceipt(transaction, receiverAccount.accountName),
                        icon: Icon(Icons.share, size: 20.w),
                        label: Text('Share', style: GoogleFonts.poppins()),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: const BorderSide(color: Color(0xFF075E54)),
                          foregroundColor: const Color(0xFF075E54),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: const Color(0xFF075E54),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _saveReceipt() async {
    try {
      // For now, just show a message that save functionality is coming soon
      // In a full implementation, you would capture the receipt as image and save it
      Get.snackbar(
        'Info',
        'Receipt save functionality coming soon!',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save receipt: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _shareReceipt(TransactionModel transaction, String receiverName) async {
    try {
      // Create share text
      final shareText = '''
💰 Payment Successful!

Amount: \$${transaction.amount.toStringAsFixed(2)}
To: $receiverName
Time: ${DateFormat('MMM dd, yyyy HH:mm').format(transaction.timestamp)}
Transaction ID: ${transaction.id}
${transaction.description.isNotEmpty ? 'Description: ${transaction.description}' : ''}

Sent via MeChat Wallet
      '''.trim();

      await Share.share(shareText, subject: 'Payment Receipt');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share receipt: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showTransferDialog(BuildContext context, PaymentController controller) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController accountNumberController = TextEditingController();
    bool useAccountNumber = false;
    String? selectedReceiverId;

    Get.dialog(
      AlertDialog(
          title: Text(
            'Send Money',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Wrap(
                  children: [
                    const Text('Transfer by:'),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('User'),
                      selected: !useAccountNumber,
                      onSelected: (selected) {
                        if (selected) setState(() => useAccountNumber = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Account Number'),
                      selected: useAccountNumber,
                      onSelected: (selected) {
                        if (selected) setState(() => useAccountNumber = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!useAccountNumber)
                  DropdownButtonFormField<String>(
                    value: selectedReceiverId,
                    decoration: InputDecoration(
                      labelText: 'Select Receiver',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    items: controller.getAvailableReceivers().map((account) {
                      return DropdownMenuItem(
                        value: account.userId,
                        child: Text(account.accountName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedReceiverId = value);
                    },
                  )
                else
                  TextFormField(
                    controller: accountNumberController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Account Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty || passwordController.text.isEmpty) {
                Get.snackbar('Error', 'Please fill all required fields');
                return;
              }

              if (!useAccountNumber && selectedReceiverId == null) {
                Get.snackbar('Error', 'Please select a receiver');
                return;
              }

              if (useAccountNumber && accountNumberController.text.isEmpty) {
                Get.snackbar('Error', 'Please enter account number');
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'Please enter a valid amount');
                return;
              }

              Get.back();
              final transaction = useAccountNumber
                  ? await controller.transferMoneyByAccountNumber(
                      accountNumberController.text.trim(),
                      amount,
                      descriptionController.text.trim().isEmpty
                          ? 'Money Transfer'
                          : descriptionController.text.trim(),
                      passwordController.text.trim(),
                    )
                  : await controller.transferMoney(
                      selectedReceiverId!,
                      amount,
                      descriptionController.text.trim().isEmpty
                          ? 'Money Transfer'
                          : descriptionController.text.trim(),
                      passwordController.text.trim(),
                    );

              if (transaction != null) {
                _showTransactionSuccessDialog(transaction, controller);
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to send money. Please try again.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
            ),
            child: Text('Send', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, PaymentController controller) {
    Get.to(() => const TransactionHistoryScreen());
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.find();

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Text(
          'Transaction History',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.transactions.isEmpty) {
          return Center(
            child: Text(
              'No transactions yet',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[500],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.transactions.length,
          itemBuilder: (context, index) {
            final transaction = controller.transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      }),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final controller = Get.find<PaymentController>();
    final isSent = transaction.transactionType == 'send';
    final amountColor = isSent ? Colors.red : Colors.green;

    // Find the counterparty name
    final counterpartyId = isSent ? transaction.receiverId : transaction.senderId;
    final counterpartyAccount = controller.allPaymentAccounts.firstWhere(
      (account) => account.userId == counterpartyId,
      orElse: () => PaymentAccountModel(
        id: '',
        userId: counterpartyId,
        accountNumber: '',
        accountName: 'Unknown User',
        balance: 0.0,
        currency: 'USD',
        isActive: true,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        password: '',
      ),
    );
    final counterpartyName = counterpartyAccount.accountName;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.r,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  transaction.description.isNotEmpty ? transaction.description : 'Money Transfer',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF075E54),
                  ),
                ),
              ),
              Text(
                '${isSent ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '${isSent ? 'To: ' : 'From: '}$counterpartyName',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            DateFormat('MMM dd, yyyy - HH:mm').format(transaction.timestamp),
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            isSent ? 'Sent' : 'Received',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: amountColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}