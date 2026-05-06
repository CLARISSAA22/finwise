//  history view screen 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../utils/constants.dart';
import '../models/models.dart';
import '../services/export_service.dart';
// all transaction screen for the history view
class AllTransactionsScreen extends StatefulWidget 
{
  const AllTransactionsScreen({super.key});
  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}
// history view screen for the user transactions
class _AllTransactionsScreenState extends State<AllTransactionsScreen> 
{
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedPayment = 'All';
  DateTimeRange? _selectedDateRange;

  String _formatDate(String raw)
  {
    return DateFormatter.format(raw);
  }

  Future<void> _selectDateRange() async 
  {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      builder: (context, child) 
      {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) 
    {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final fp = Provider.of<FinanceProvider>(context);
    final List<Transaction> transactions = fp.transactions;

    final categories = <String>{'All'}..addAll(transactions.map((t) => t.category));
    final payments = <String>{'All'}..addAll(transactions.map((t) => t.paymentMethod));

    final filtered = transactions.where((tx) {
      final matchesSearch = _searchCtrl.text.isEmpty ||
          (tx.description.toLowerCase().contains(_searchCtrl.text.toLowerCase()));
      final matchesCategory = _selectedCategory == 'All' || (tx.category == _selectedCategory);
      final matchesPayment = _selectedPayment == 'All' || (tx.paymentMethod == _selectedPayment);

      bool matchesDate = true;
      if (_selectedDateRange != null) {
        try {
          final txDate = DateFormat('yyyy-MM-dd').parse(tx.date);
          matchesDate = txDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
              txDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
        } catch (_) {}
      }

      return matchesSearch && matchesCategory && matchesPayment && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: () => ExportService.exportTransactionsToCsv(filtered),
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, color: _selectedDateRange == null ? AppColors.textLight : AppColors.primary),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => setState(() => _selectedDateRange = null),
              tooltip: 'Clear Date Filter',
            ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Showing: ${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search description...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      )),
                  const SizedBox(width: 12),
                  ...payments.map((pm) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(pm),
                          selected: _selectedPayment == pm,
                          onSelected: (_) => setState(() => _selectedPayment = pm),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No transactions match the criteria.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: AppColors.borderRadius),
                          child: InkWell(
                            onTap: () => _showTransactionDetail(tx, fp),
                            borderRadius: AppColors.borderRadius,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tx.category ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                                      const SizedBox(height: 4),
                                      Text(_formatDate(tx.date),
                                          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${tx.type == 'expense' ? '-' : '+'}₹${tx.amount?.toStringAsFixed(0) ?? '0'}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: tx.type == 'expense' ? Colors.red : Colors.green)),
                                      const SizedBox(height: 4),
                                      Text(tx.paymentMethod ?? '',
                                          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(dynamic tx, FinanceProvider fp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tx.category, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Transaction'),
                          content: const Text('Are you sure you want to delete this transaction?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await fp.deleteTransaction(tx.id);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const Divider(),
              _detailRow(Icons.calendar_today, 'Date', _formatDate(tx.date)),
              _detailRow(Icons.account_balance_wallet, 'Amount', '₹${tx.amount.toStringAsFixed(2)}'),
              _detailRow(Icons.payment, 'Method', tx.paymentMethod),
              _detailRow(Icons.notes, 'Description', tx.description ?? 'No description'),
              _detailRow(Icons.mood, 'Mood', tx.mood ?? 'Neutral'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textDark))),
        ],
      ),
    );
  }
}

