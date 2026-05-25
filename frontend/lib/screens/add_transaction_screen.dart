import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../services/upi_service.dart';
import '../services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
// add transation screen  the api that is user for upi transaction 
class AddTransactionScreen extends StatefulWidget 
{// intialization of transation 
  final double? initialAmount;
  final String? initialDescription;
  final String? initialUpiId;
  final String? initialUpiName;
  final String? initialUpiVpa;
// this is constuctor for transation screen and the values are optional
  const AddTransactionScreen(
    {
    super.key, 
    this.initialAmount, 
    this.initialDescription, 
    this.initialUpiId, 
    this.initialUpiName,
    this.initialUpiVpa,
  }
  );
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}
 // form for transation default values and the animation controler is for the animation of the screen
class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin 
{
  // controllers for the form fields
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'Expense';// type of the transaction and the default value is Expense 
  String _category = 'Food';// category of the transaction and the default value is Food 
  String _mood = 'Neutral';// mood of the transaction and the default value is Neutral 
  String _paymentMethod = 'Cash';// payment method of the transaction and the default value is Cash
  DateTime _selectedDate = DateTime.now();// selected date of the transaction and the default value is current date
  final TextEditingController _upiNameCtrl = TextEditingController();// text controller for the upi name
  final TextEditingController _upiVpaCtrl = TextEditingController();// text controller for the upi vpa
  final TextEditingController _upiRefCtrl = TextEditingController();// text controller for the upi reference
  final TextEditingController _upiIdCtrl = TextEditingController();// text controller for the upi id
  final TextEditingController _upiPhoneCtrl = TextEditingController();// text controller for the upi phone number
  bool _isSaving = false;// boolean to check if the transaction is saving
  late AnimationController _animController;// animation controller for the screen
  late Animation<double> _fadeAnimation;// fade animation for the screen
  late RazorpayService _razorpayService;// razorpay service for the screen
// list of categeries and the type of Transation mood and type of payment
  final List<String> _expenseCategories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Misc'];
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investments', 'Gifts', 'Misc'];
  final List<String> _moods = ['Happy', 'Sad', 'Stressed', 'Excited', 'Neutral'];
  final List<String> _paymentMethods = ['Cash', 'Card', 'UPI'];
  List<String> get _currentCategories 
  {
    if (_type == 'income') 
    {
      return _incomeCategories;
    }
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    final budgetCats = fp.budgets.map((b) => b.category).toList();
    // Case-insensitive unique set: prefer capitalized version if available
    final Map<String, String> uniqueMap = {};
    for (var cat in [..._expenseCategories, ...budgetCats]) 
    {
      final key = cat.toLowerCase().trim();
      if (!uniqueMap.containsKey(key) || (cat[0].toUpperCase() == cat[0] && uniqueMap[key]![0].toLowerCase() == uniqueMap[key]![0])) 
      {
        uniqueMap[key] = cat;
      }
    }
    return uniqueMap.values.toList();
  }
// initial state of the screen and the animation controller is initialized here
  @override
  void initState() 
  {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
// Initialize with QR data if available
    _amountCtrl.text = widget.initialAmount?.toStringAsFixed(0) ?? '';
    _descCtrl.text = widget.initialDescription ?? '';
    if (widget.initialUpiId != null) 
    {
      _paymentMethod = 'UPI';
    }
    // razorpay service for the screen and the callback functions are defined here
    _razorpayService = RazorpayService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    // Fetch budgets to show remaining info
    WidgetsBinding.instance.addPostFrameCallback((_) 
    {
      Provider.of<FinanceProvider>(context, listen: false).fetchBudgets();
    }
    );
  }
// dispose function to dispose the controller and the services
  @override
  void dispose()
 {
    _razorpayService.dispose();
    _animController.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
// handle payment success function 
  void _handlePaymentSuccess(PaymentSuccessResponse response) 
  {
    _saveTransactionRow(response.paymentId ?? 'razorpay_success');
  }
// handle payment error function
  void _handlePaymentError(PaymentFailureResponse response) 
  {
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red,content: Text('Payment Failed: ${response.message}'),
    ));
  }
// handle external wallet function
  void _handleExternalWallet(ExternalWalletResponse response) 
  {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet: ${response.walletName}'),
    ));
  }
// save transation row function
  void _saveTransactionRow(String upiRef) async 
  {
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final error = await financeProvider.addTransaction({
      'amount': double.parse(_amountCtrl.text),
      'type': _type,
      'category': _category,
      'date': _selectedDate.toIso8601String().substring(0, 16).replaceFirst('T', ' '),
      'description': _descCtrl.text,
      'mood': _mood,
      'payment_method': _paymentMethod,
      'upi_ref': upiRef,
    }
    );

    if (error == null && mounted) 
    {
      // Update balance in AuthProvider
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Transaction saved successfully!', style: TextStyle(color: Colors.white)),
      ));
      _amountCtrl.clear();
      _descCtrl.clear();
      Navigator.pop(context);
    } 
    else if (mounted) 
    {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        content: Text('Error: $error', style: const TextStyle(color: Colors.white, fontSize: 12)),
      ));
    }
  }
// save transation function with razorpay integration
  void _saveTransaction({bool payNow = false}) async 
  {
    if (_isSaving) 
    return;
    
    if (_amountCtrl.text.isEmpty)
     {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }
    final double? amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) 
    {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    // If it's a digital payment (Card or UPI) and the user chose to "Pay"
    if (_type == 'expense' && payNow && (_paymentMethod == 'Card' || _paymentMethod == 'UPI')) {
      setState(() => _isSaving = true);
      
      if (_paymentMethod == 'UPI') {
        _processUpiPayment(amt);
        return;
      } else {
        // Fallback to Razorpay for Card payments
        final orderId = await financeProvider.createRazorpayOrder(amt);
        _razorpayService.openCheckout(
          amount: amt,
          description: _descCtrl.text.isEmpty ? 'FinWise Payment' : _descCtrl.text,
          orderId: orderId,
        );
        return;
      }
    }

    // Otherwise, save manually (Cash or unpaid UPI/Card)
    setState(() => _isSaving = true);
    _saveTransactionRow('');
    setState(() => _isSaving = false);
  }

  // Helper for UPI FR-12 / FR-13 loop and error parsing
  Future<void> _processUpiPayment(double amt) async {
    String? launchedStr = await UpiService.launchUpiPayment(
      amount: amt,
      upiId: widget.initialUpiId ?? ApiConstants.upiId,
      upiName: widget.initialUpiName ?? ApiConstants.upiName,
      note: _descCtrl.text.isEmpty ? 'FinWise Payment' : _descCtrl.text,
    );

    // DEV MOCK: If user sets amount to exactly 99999, simulate a bank limit error for testing
    if (amt == 99999) {
      launchedStr = "responseCode=U06&Status=FAILURE&txnRef=MOCK123";
    }

    if (!mounted) return;

    if (launchedStr == null || launchedStr == 'APP_NOT_FOUND') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find a UPI app.')));
      setState(() => _isSaving = false);
      return;
    }

    // 1. Detect error messages containing "bank limit" or codes U06 / ZP009
    final lowerRes = launchedStr.toLowerCase();
    final isBankLimitError = lowerRes.contains('u06') || lowerRes.contains('zp009') || 
                             lowerRes.contains('bank limit') || lowerRes.contains('exceeded');

    if (isBankLimitError) {
      // 2. Halve amount, cap at 5000
      double nextAmt = amt / 2;
      if (nextAmt > 5000) nextAmt = 5000;
      nextAmt = double.parse(nextAmt.toStringAsFixed(0)); // round to integer

      // 5. Stop if below 100
      if (nextAmt < 100) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Payment Failed'),
            content: const Text('Bank limit exceeded. Minimum retry amount (₹100) reached. Please use a different payment method.'),
            actions: [
              TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _isSaving = false); }, child: const Text('OK'))
            ],
          )
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Bank Limit Exceeded'),
          content: Text('You attempted ₹${amt.toStringAsFixed(0)}, but your bank limit was exceeded (U06).\n\nWould you like to retry with ₹${nextAmt.toStringAsFixed(0)}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isSaving = false);
              },
              child: const Text('Change amount', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // 3. Automatically re-initiate same UPI payment with reduced amount
                _processUpiPayment(nextAmt);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: Text('Retry with ₹${nextAmt.toStringAsFixed(0)}'),
            ),
          ],
        ),
      );
      return;
    }

    // 4. Automatically save transaction and navigate to front page
    // Update text field to reflect final amount if it was halved
    if (_amountCtrl.text != amt.toStringAsFixed(0)) {
      _amountCtrl.text = amt.toStringAsFixed(0);
    }
    _saveTransactionRow('UPI_${DateTime.now().millisecondsSinceEpoch}');
  }

// build budget info function
  Widget _buildBudgetInfo() {
    if (_type != 'expense') return const SizedBox.shrink();
    
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        final budget = fp.budgets.cast<Budget?>().firstWhere(
          (b) => b?.category.toLowerCase() == _category.toLowerCase(),
          orElse: () => null,
        );

        if (budget == null) return const SizedBox.shrink();

        final double amountEntered = double.tryParse(_amountCtrl.text) ?? 0.0;
        final currentRemaining = budget.limitAmount - budget.spent;
        final pendingRemaining = currentRemaining - amountEntered;
        final isOver = pendingRemaining < 0;
// column for the budget info
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
              color: isOver ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOver ? Colors.red.shade200 : Colors.blue.shade200),
              ),
// column for the budget info
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: isOver ? Colors.red : Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Budget Remaining: ',
                        style: TextStyle(fontWeight: FontWeight.w500, color: isOver ? Colors.red : Colors.blue.shade900),
                      ),
                        Expanded(
                          child: Text(
                            '₹${currentRemaining.toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: isOver ? Colors.red : Colors.blue.shade900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (amountEntered > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 28),
                          Text(
                            'Pending After This: ',
                            style: TextStyle(fontSize: 13, color: isOver ? Colors.red.shade700 : Colors.blue.shade700),
                          ),
                          Expanded(
                            child: Text(
                              '₹${pendingRemaining.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isOver ? Colors.red.shade700 : Colors.blue.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
// build type toggle function
  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _type = 'expense';
                  _category = _expenseCategories.first;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == 'expense' ? Colors.redAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _type == 'expense'
                      ? [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Expense',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _type == 'expense' ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _type = 'income';
                  _category = _incomeCategories.first;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == 'income' ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _type == 'income'
                      ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Income',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _type == 'income' ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggle(),
              const SizedBox(height: 24),
              // Card for Inputs
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    // Amount Input
                    TextField(
                      controller: _amountCtrl,
                      onChanged: (v) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, size: 28, color: AppColors.primary),
                        labelText: 'Amount',
                        labelStyle: const TextStyle(fontSize: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _currentCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    _buildBudgetInfo(),
                    const SizedBox(height: 16),
                    // Description Input
                    TextField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Note (Optional)',
                        prefixIcon: const Icon(Icons.notes, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Selector
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: AppColors.primary),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (d != null) {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(primary: AppColors.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (t != null) {
                            setState(() => _selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                          } else {
                            setState(() => _selectedDate = DateTime(d.year, d.month, d.day, _selectedDate.hour, _selectedDate.minute));
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Date & Time: ${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year} ${_selectedDate.hour.toString().padLeft(2,'0')}:${_selectedDate.minute.toString().padLeft(2,'0')}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_type == 'expense') ...[
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                      // Mood Dropdown
                      DropdownButtonFormField<String>(
                        value: _mood,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
                        decoration: InputDecoration(
                          labelText: 'Mood',
                          prefixIcon: const Icon(Icons.mood, color: AppColors.accent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                        onChanged: (v) => setState(() => _mood = v!),
                      ),
                      const SizedBox(height: 16),
                      // Payment Method Dropdown
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondary),
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: const Icon(Icons.wallet, color: AppColors.secondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _paymentMethods.map((pm) => DropdownMenuItem(value: pm, child: Text(pm, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Unified Action Button
              if (_type == 'expense' && (_paymentMethod == 'UPI' || _paymentMethod == 'Card') && widget.initialUpiId == null)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: _isSaving ? null : () => _saveTransaction(payNow: true),
                        child: _isSaving 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Text(_paymentMethod == 'UPI' ? 'Save & Pay' : 'Pay Now', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: _isSaving ? null : () => _saveTransaction(payNow: false),
                        child: _isSaving 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: (_type == 'expense' && _paymentMethod == 'UPI')
                        ? [AppColors.secondary, const Color(0xFF00897B)]
                        : [AppColors.primary, const Color(0xFF1565C0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_type == 'expense' && _paymentMethod == 'UPI')
                          ? AppColors.secondary.withOpacity(0.4)
                          : AppColors.primary.withOpacity(0.4),
                        blurRadius: 10, 
                        offset: const Offset(0, 4)
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      minimumSize: const Size(0, 56),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : () => _saveTransaction(payNow: true),
                    child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          (_type == 'expense' && _paymentMethod == 'UPI')
                            ? 'Save & Pay via UPI'
                            : (_type == 'expense' && _paymentMethod == 'Card')
                              ? 'Pay Now (₹${_amountCtrl.text.isEmpty ? "0" : _amountCtrl.text})'
                              : 'Save Transaction',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)
                        ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
