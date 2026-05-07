import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../widgets/upi_widgets.dart';
import '../services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/notification_service.dart';
import '../services/upi_service.dart';
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late RazorpayService _razorpayService;
  Subscription? _pendingSub;
  String _pendingMethod = 'UPI';

  @override
  void initState() {
    super.initState();
    _fetchAndSchedule();
    _razorpayService = RazorpayService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingSub != null) {
      final fp = Provider.of<FinanceProvider>(context, listen: false);
      final result = await fp.paySubscription(_pendingSub!.id, _pendingMethod);
      if (result != null) {
        final nextDue = _formatDate(result['next_due_date'] ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[700],
            content: Text('✅ ₹${_pendingSub!.amount.toStringAsFixed(0)} paid via $_pendingMethod! Next due: $nextDue'),
          ),
        );
      }
      setState(() => _pendingSub = null);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> _fetchAndSchedule() async {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    await fp.fetchSubscriptions();
    for (var sub in fp.subscriptions) {
      NotificationService.scheduleDueReminder(sub);
    }
  }


  // ──────────────────────────── helpers ──────────────────────────────

  /// Converts 'yyyy-MM-dd' → '18 Apr 2026'
  String _formatDate(String raw) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  // ──────────────────────────── add dialog ───────────────────────────

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String cycle = 'monthly';
    DateTime dueDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Subscription'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number),
                DropdownButton<String>(
                  value: cycle,
                  onChanged: (v) => setState(() => cycle = v!),
                  items: ['monthly', 'yearly']
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Due: '),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100));
                        if (d != null) setState(() => dueDate = d);
                      },
                      child: Text(DateFormat('dd MMM yyyy').format(dueDate)),
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                  final fp =
                      Provider.of<FinanceProvider>(context, listen: false);
                  await fp.addSubscription({
                    'name': nameCtrl.text,
                    'amount': double.parse(amountCtrl.text),
                    'billing_cycle': cycle,
                    'next_due_date':
                        DateFormat('yyyy-MM-dd').format(dueDate),
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  // ──────────────────────────── edit dialog ───────────────────────────

  void _showEditDialog(Subscription sub) {
    final nameCtrl = TextEditingController(text: sub.name);
    final amountCtrl = TextEditingController(text: sub.amount.toString());
    String cycle = sub.billingCycle.isNotEmpty ? sub.billingCycle : 'monthly';
    DateTime dueDate = DateTime.now();
    try {
      dueDate = DateFormat('yyyy-MM-dd').parse(sub.nextDueDate);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Subscription'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number),
                DropdownButton<String>(
                  value: cycle,
                  onChanged: (v) => setState(() => cycle = v!),
                  items: ['monthly', 'yearly']
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Due: '),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime(2100));
                        if (d != null) setState(() => dueDate = d);
                      },
                      child: Text(DateFormat('dd MMM yyyy').format(dueDate)),
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                  final fp =
                      Provider.of<FinanceProvider>(context, listen: false);
                  await fp.editSubscription(sub.id, {
                    'name': nameCtrl.text,
                    'amount': double.parse(amountCtrl.text),
                    'billing_cycle': cycle,
                    'next_due_date':
                        DateFormat('yyyy-MM-dd').format(dueDate),
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  // ──────────────────────────── pay dialog ───────────────────────────

  Future<void> _showPayDialog(Subscription sub) async {
    String selectedMethod = 'UPI';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.payment, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Pay – ${sub.name}',
                    style: const TextStyle(fontSize: 17,fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${sub.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              // UPI / Card toggle
              Row(
                children: ['UPI', 'Card', 'Cash'].map((method) {
                  final selected = selectedMethod == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(method),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontSize: 12),
                      onSelected: (_) =>
                          setState(() => selectedMethod = method),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (selectedMethod == 'UPI') ...[
                const Text('Select UPI App:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 12),
                UpiAppPicker(onSelect: (val) => Navigator.pop(context, val)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    // Show loading snackbar while payment processes
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: Colors.white)),
          const SizedBox(width: 12),
          Text('Processing ${sub.name} payment…'),
        ]),
        duration: const Duration(seconds: 3),
      ),
    );

    // If UPI is selected, launch the native intent
    if (selectedMethod == 'UPI') {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final launched = await UpiService.launchUpiPayment(
        amount: sub.amount,
        upiId: auth.currentUser?.upiId ?? ApiConstants.upiId,
        upiName: auth.currentUser?.name ?? ApiConstants.upiName,
        note: 'Subscription: ${sub.name}',
      );
      
      if (!mounted) return;
      final isLaunched = launched != null && launched != 'APP_NOT_FOUND';
      if (isLaunched) {
        // Assume success for demo
        final fp = Provider.of<FinanceProvider>(context, listen: false);
        final result = await fp.paySubscription(sub.id, selectedMethod);
        if (result != null && mounted) {
          final nextDue = _formatDate(result['next_due_date'] ?? '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green[700],
              content: Text('✅ ₹${sub.amount.toStringAsFixed(0)} paid via UPI! Next due: $nextDue'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find a UPI app (GPay, PhonePe, etc.)')),
        );
      }
      return;
    }

    // If Card is selected, use Razorpay
    if (selectedMethod == 'Card') {
      final fp = Provider.of<FinanceProvider>(context, listen: false);
      final orderId = await fp.createRazorpayOrder(sub.amount);
      
      setState(() {
        _pendingSub = sub;
        _pendingMethod = selectedMethod;
      });

      _razorpayService.openCheckout(
        amount: sub.amount,
        description: 'Subscription: ${sub.name}',
        orderId: orderId,
      );
      return;
    }

    final fp = Provider.of<FinanceProvider>(context, listen: false);
    final result = await fp.paySubscription(sub.id, selectedMethod);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result != null) {
      final nextDue = _formatDate(result['next_due_date'] ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text(
              '✅ ₹${sub.amount.toStringAsFixed(0)} paid via $selectedMethod! '
              'Next due: $nextDue'),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('❌ Payment failed. Please try again.'),
        ),
      );
    }
  }

  // ──────────────────────────── build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);

    // FR-10 Renewal alerts (one-time, deduplicated by snackbar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var sub in financeProvider.subscriptions) {
        if (sub.isDueSoon && sub.dueInDays >= 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Alert: ${sub.name} is due in ${sub.dueInDays} days!')));
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: financeProvider.subscriptions.isEmpty
          ? const Center(child: Text('No active subscriptions.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: financeProvider.subscriptions.length,
              itemBuilder: (context, index) {
                final sub = financeProvider.subscriptions[index];

                // Due today (0) or overdue (<0) → show Pay button
                final isDueOrOverdue = sub.dueInDays <= 0;
                final isOverdue = sub.dueInDays < 0;

                String dueLabel;
                Color dueColor;
                if (isOverdue) {
                  dueLabel = 'Overdue by ${sub.dueInDays.abs()} day(s)';
                  dueColor = Colors.red;
                } else if (sub.dueInDays == 0) {
                  dueLabel = 'Due TODAY';
                  dueColor = Colors.orange[800]!;
                } else if (sub.isDueSoon) {
                  dueLabel = 'Due in ${sub.dueInDays} day(s)';
                  dueColor = Colors.orange;
                } else {
                  dueLabel = 'Due ${_formatDate(sub.nextDueDate)}';
                  dueColor = Colors.grey[600]!;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isDueOrOverdue ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDueOrOverdue
                        ? BorderSide(
                            color: isOverdue
                                ? Colors.red
                                : Colors.orange,
                            width: 1.5)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── top row: name & delete ──
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                sub.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditDialog(sub),
                                  tooltip: 'Edit subscription',
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => financeProvider
                                      .deleteSubscription(sub.id),
                                  tooltip: 'Cancel subscription',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ── amount & cycle ──
                        Text(
                          '₹${sub.amount.toStringAsFixed(2)}  •  ${sub.billingCycle}',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        // ── due label ──
                        Row(
                          children: [
                            Icon(
                              isDueOrOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.calendar_today,
                              size: 15,
                              color: dueColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dueLabel,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: dueColor,
                                  fontWeight: isDueOrOverdue
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                            ),
                          ],
                        ),
                        // ── Pay button (always visible) ──
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOverdue
                                  ? Colors.red[700]
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                            ),
                            icon: const Icon(Icons.payment),
                            label: Text(isDueOrOverdue ? 'Pay via UPI / Card' : 'Pay Early via UPI / Card'),
                            onPressed: () => _showPayDialog(sub),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
