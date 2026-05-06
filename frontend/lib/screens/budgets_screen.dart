import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../utils/constants.dart';
//budget screen setup 
class BudgetsScreen extends StatefulWidget 
{
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}
// budget screen code 
class _BudgetsScreenState extends State<BudgetsScreen> 
{
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Misc'];
//budget screen code setup
    @override
    void initState() 
  {
    super.initState();
    _refreshBudgets();
  } 
  //budget screen code setup
  Future<void> _refreshBudgets() async 
  {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    await fp.fetchBudgets();
    // Check for alerts only once after fetch
    if (mounted) {
      for (var bg in fp.budgets) 
      {
        if (bg.spent >= bg.limitAmount && bg.limitAmount > 0) 
        {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.accent,
            content: Text('Over Budget: ${bg.category}!', 
            style: const TextStyle(color: Colors.white)),
          ));
        } 
        else if (bg.spent >= bg.limitAmount * 0.8 && bg.limitAmount > 0) 
        {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Warning: 80% reached for ${bg.category}'),
          ));
        }
      }
    }
  }
  // add budget function 
  void _addBudget() async 
  {
    if (_amountCtrl.text.isEmpty) 
    {
      return;
    }
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final now = DateTime.now();
    final monthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final success = await financeProvider.addBudget({
      'category': _selectedCategory,
      'limit_amount': double.parse(_amountCtrl.text),
      'month_year': monthYear
    });
    if (success && mounted) 
    {
      _amountCtrl.clear();
      Navigator.pop(context);
    }
  }
  // budget screen code setup
  void _showAddDialog()
  {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('New Monthly Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: 
        [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _amountCtrl, decoration: 
          const InputDecoration(labelText: 'Limit Amount (₹)'), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), 
        child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: _addBudget, 
          child: const Text('Set Budget', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) 
  {
    final fp = Provider.of<FinanceProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(onRefresh: _refreshBudgets,
        child: fp.budgets.isEmpty 
          ? const Center(child: Text('No budgets found. Plan your spending!'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: fp.budgets.length, 
              itemBuilder: (context, index) 
              {
                final bg = fp.budgets[index];
                final progress = bg.limitAmount > 0 ?(bg.spent / bg.limitAmount) : 0.0;
                return Container(margin: const EdgeInsets.only(bottom: 20),padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white,borderRadius: AppColors.borderRadius,boxShadow: AppColors.shadow),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(bg.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
                          Text('₹${bg.spent.toStringAsFixed(0)} / ₹${bg.limitAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: progress > 1.0 ? Colors.red : AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: progress > 1.0 ? 1.0 : progress,backgroundColor: AppColors.primaryLight,color: progress > 0.9 ? Colors.red : (progress > 0.8 ? Colors.orange : AppColors.secondary),minHeight: 10),
                      ),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).toStringAsFixed(0)}% used', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
