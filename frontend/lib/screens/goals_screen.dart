import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../services/upi_service.dart';
import '../services/notification_service.dart';
import '../services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../utils/constants.dart';
//goals screen setup 
class GoalsScreen extends StatefulWidget
{
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
{
  late RazorpayService _razorpayService;
  Goal? _pendingGoal;
  double _pendingAmount = 0;
  @override
  void initState() 
  {
    super.initState();
    Future.microtask(() => Provider.of<FinanceProvider>(context, listen: false).fetchGoals());  
    _razorpayService = RazorpayService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() 
  {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async
   {
    if (_pendingGoal != null && _pendingAmount > 0) {
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
    
      await finance.editGoal(
        _pendingGoal!.id,
        _pendingGoal!.targetAmount,
        _pendingGoal!.currentAmount + _pendingAmount,
        _pendingGoal!.deadline,
        _pendingGoal!.description,
        _pendingGoal!.autoSavePercentage,
      );
      auth.fetchProfile();
      if (_pendingGoal!.currentAmount + _pendingAmount >= _pendingGoal!.targetAmount) 
      {
        NotificationService.showGoalCompletedNotification(_pendingGoal!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('₹$_pendingAmount added to ${_pendingGoal!.description}!'), backgroundColor: Colors.green),
      );
      setState(() {
        _pendingGoal = null;
        _pendingAmount = 0;
      });
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

  void _showGoalForm(BuildContext context, FinanceProvider finance, [Goal? goal]) {
    final titleCtl = TextEditingController(text: goal?.description);
    final targetCtl = TextEditingController(text: goal?.targetAmount.toString());
    final currentCtl = TextEditingController(text: goal?.currentAmount.toString() ?? '0');
    final autoSaveCtl = TextEditingController(text: goal?.autoSavePercentage.toString() ?? '0');
    DateTime date = goal != null ? DateFormat('yyyy-MM-dd').parse(goal.deadline) : DateTime.now().add(Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(goal == null ? 'New Goal' : 'Edit Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(controller: titleCtl, decoration: InputDecoration(labelText: 'Description (e.g., Vacation)')),
                  TextField(controller: targetCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Target Amount')),
                  TextField(controller: currentCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Current Saved Amount')),
                  TextField(controller: autoSaveCtl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Auto-save % of Monthly Balance')),
                  ListTile(
                    title: Text('Deadline: ${DateFormat('dd MMM yyyy').format(date)}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setModalState(() => date = picked);
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final target = double.tryParse(targetCtl.text) ?? 0;
                      final current = double.tryParse(currentCtl.text) ?? 0;
                      final autoSave = double.tryParse(autoSaveCtl.text) ?? 0;
                      final desc = titleCtl.text;
                      if (target > 0 && desc.isNotEmpty) {
                        if (goal == null) {
                          await finance.addGoal(target, current, DateFormat('yyyy-MM-dd').format(date), desc, autoSave);
                        } else {
                          await finance.editGoal(goal.id, target, current, DateFormat('yyyy-MM-dd').format(date), desc, autoSave);
                        }
                        Provider.of<AuthProvider>(context, listen: false).fetchProfile(); // Sync balance
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Save Goal'),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  /// Converts 'yyyy-MM-dd' to a friendly format like '18 Apr 2026'
  String _formatDate(String raw) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('My Savings Goals')),
      body: finance.goals.isEmpty
          ? Center(child: Text('No goals added yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: finance.goals.length,
              itemBuilder: (context, i) {
                final g = finance.goals[i];
                final progress = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) : 0.0;
                final isCompleted = progress >= 1.0;

                return Dismissible(
                  key: Key(g.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: EdgeInsets.only(right: 20), child: Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (_) {
                    finance.deleteGoal(g.id);
                    auth.fetchProfile(); // Sync balance
                  },
                  child: Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: isCompleted ? 4 : 1,
                    shadowColor: isCompleted ? Colors.green.withOpacity(0.5) : Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isCompleted ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () => _showGoalForm(context, finance, g),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(g.description, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('₹${g.currentAmount.toStringAsFixed(0)} / ₹${g.targetAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.blue)),
                              ],
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              color: isCompleted ? Colors.green : Colors.blue,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 12),
                            if (isCompleted)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars, color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Goal Completed! 🎉',
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final success = await finance.withdrawGoal(g.id);
                                        if (success) {
                                          auth.fetchProfile(); // Update total balance
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('₹${g.currentAmount.toStringAsFixed(0)} moved to your savings!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(0, 32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Move to Savings', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Deadline: ${_formatDate(g.deadline)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                TextButton.icon(
                                  onPressed: () => _showAddMoneyDialog(context, finance, g),
                                  icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
                                  label: const Text('Add Money', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                ),
                              ],
                            ),
                            if (g.autoSavePercentage > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Auto-save: ${g.autoSavePercentage.toInt()}% of monthly balance', style: TextStyle(color: Colors.blue, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalForm(context, finance),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, FinanceProvider finance, Goal goal) {
    final amountCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contribute to ${goal.description}'),
        content: TextField(
          controller: amountCtl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          // Save Manually Button
          TextButton(
            onPressed: () async {
              final val = double.tryParse(amountCtl.text) ?? 0;
              if (val > 0) {
                await finance.editGoal(
                  goal.id, 
                  goal.targetAmount, 
                  goal.currentAmount + val, 
                  goal.deadline, 
                  goal.description,
                  goal.autoSavePercentage
                );
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.fetchProfile(); // Sync balance
                if (goal.currentAmount + val >= goal.targetAmount) {
                  NotificationService.showGoalCompletedNotification(goal);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ₹$val manually to ${goal.description}!')));
              }
            },
            child: const Text('Save Manually', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(amountCtl.text) ?? 0;
              if (val > 0) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final launched = await UpiService.launchUpiPayment(
                  amount: val,
                  upiId: auth.currentUser?.upiId ?? ApiConstants.upiId,
                  upiName: auth.currentUser?.name ?? ApiConstants.upiName,
                  note: 'Goal: ${goal.description}',
                );
                
                final isLaunched = launched != null && launched != 'APP_NOT_FOUND';
                if (isLaunched && context.mounted) {
                   await finance.editGoal(
                     goal.id, 
                     goal.targetAmount, 
                     goal.currentAmount + val, 
                     goal.deadline, 
                     goal.description,
                     goal.autoSavePercentage
                   );
                   final auth = Provider.of<AuthProvider>(context, listen: false);
                   auth.fetchProfile(); // Sync balance
                   if (goal.currentAmount + val >= goal.targetAmount) {
                     NotificationService.showGoalCompletedNotification(goal);
                   }
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ₹$val to ${goal.description}!')));
                } else if (!isLaunched && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not find a UPI app (GPay, PhonePe, etc.)')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Pay Using UPI'),
          ),
        ],
      ),
    );
  }
}