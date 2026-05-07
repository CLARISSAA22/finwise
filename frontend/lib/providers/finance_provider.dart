import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
//user for finance provider  and fechtch data from backend
class FinanceProvider with ChangeNotifier 
{
  final ApiService _apiService = ApiService();
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<Subscription> _subscriptions = [];
  List<Goal> _goals = [];
  Map<String, dynamic> _insights = {};
  //getters for finance provider 
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<Subscription> get subscriptions => _subscriptions;
  List<Goal> get goals => _goals;
  Map<String, dynamic> get insights => _insights;

  Future<void> fetchTransactions() async 
  {
    try 
    {
      final response = await _apiService.getRequest('/transactions');
      if (response.statusCode == 200) 
      {
        final data = jsonDecode(response.body);
        _transactions = (data['transactions'] as List).map((t) => Transaction.fromJson(t)).toList();
        notifyListeners();
      }
    }
     catch (e) 
    {
      debugPrint('fetchTransactions error: $e');
    }
  }
  Future<String?> addTransaction(Map<String, dynamic> txData) async {
    try 
    {
      final response = await _apiService.postRequest('/transactions', txData);
      if (response.statusCode == 201)
      {
        await fetchTransactions();
        return null; // null = success
      }
      final msg = 'Server error ${response.statusCode}: ${response.body}';
      debugPrint('addTransaction failed: $msg');
      return msg;
    } 
    catch (e) 
    {
      debugPrint('addTransaction error: $e');
      return e.toString(); // return actual error
    }
  }

  Future<bool> deleteTransaction(int id) async 
  {
    final response = await _apiService.deleteRequest('/transactions/$id');
    if (response.statusCode == 200) 
    {
      await fetchTransactions();
      return true;
    }
    return false;
  }

  Future<void> fetchBudgets() async 
  {
    try 
    {
      final response = await _apiService.getRequest('/budgets');
      if (response.statusCode == 200) 
      {
        final data = jsonDecode(response.body);
        _budgets = (data['budgets'] as List).map((b) => Budget.fromJson(b)).toList();
        notifyListeners();
      }
    }
    catch (e) 
    {
      debugPrint('fetchBudgets error: $e');
    }
  }

  Future<bool> addBudget(Map<String, dynamic> bgData) async 
  {
    final response = await _apiService.postRequest('/budgets', bgData);
    if (response.statusCode == 201) 
    {
      await fetchBudgets();
      return true;
    }
    return false;
  }

  Future<void> fetchSubscriptions() async 
  {
    final response = await _apiService.getRequest('/subscriptions');
    if (response.statusCode == 200) 
    {
      final data = jsonDecode(response.body);
      _subscriptions = (data['subscriptions'] as List).map((s) => Subscription.fromJson(s)).toList();
      notifyListeners();
    }
  }

  Future<bool> addSubscription(Map<String, dynamic> subData) async 
  {
    final response = await _apiService.postRequest('/subscriptions', subData);
    if (response.statusCode == 201) 
    {
      await fetchSubscriptions();
      return true;
    }
    return false;
  }

  Future<bool> deleteSubscription(int id) async 
  {
    final response = await _apiService.deleteRequest('/subscriptions/$id');
    if (response.statusCode == 200) 
    {
      await fetchSubscriptions();
      return true;
    }
    return false;
  }
  /// Pay a subscription — records as expense transaction, advances next_due_date.
  Future<Map<String, dynamic>?> paySubscription(int id, String paymentMethod) async 
  {
    try 
    {
      final response = await _apiService.postRequest(
        '/subscriptions/$id/pay',
        {'payment_method': paymentMethod},
      );
      if (response.statusCode == 201) 
      {
        await fetchSubscriptions();
        await fetchTransactions();
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('paySubscription failed: ${response.statusCode} ${response.body}');
      return null;
    } 
    catch (e) 
    {
      debugPrint('paySubscription error: $e');
      return null;
    }
  }

  Future<void> fetchGoals() async 
  {
    final response = await _apiService.getRequest('/goals');
    if (response.statusCode == 200) 
    {
      final data = jsonDecode(response.body);
      _goals = (data['goals'] as List).map((g) => Goal.fromJson(g)).toList();
      notifyListeners();
    }
  }

  Future<bool> addGoal(double target, double current, String deadline, String description, double autoSavePercentage) async {
    final response = await _apiService.postRequest('/goals', 
    {
      'target_amount': target,
      'current_amount': current,
      'deadline': deadline,
      'description': description,
      'auto_save_percentage': autoSavePercentage
    }
    );
    if (response.statusCode == 201) 
    {
      await fetchGoals();
      await fetchTransactions();
      return true;
    }
    return false;
  }

  Future<bool> editGoal(int id, double target, double current, String deadline, String description, double autoSavePercentage) async {
    final response = await _apiService.putRequest('/goals/$id', 
    {
      'target_amount': target,
      'current_amount': current,
      'deadline': deadline,
      'description': description,
      'auto_save_percentage': autoSavePercentage
    }
    );
    if (response.statusCode == 200) 
    {
      await fetchGoals();
      await fetchTransactions();
      return true;
    }
    return false;
  }

  Future<bool> deleteGoal(int id) async 
  {
    final response = await _apiService.deleteRequest('/goals/$id');
    if (response.statusCode == 200) 
    {
      await fetchGoals();
      return true;
    }
    return false;
  }

  Future<bool> withdrawGoal(int id) async 
  {
    final response = await _apiService.postRequest('/goals/$id/withdraw', {});
    if (response.statusCode == 200) 
    {
      await fetchGoals();
      await fetchTransactions();
      return true;
    }
    return false;
  }
  Future<void> fetchInsights() async 
  {
    final response = await _apiService.getRequest('/insights');
    if (response.statusCode == 200) 
    {
      _insights = jsonDecode(response.body);
      notifyListeners();
    }
  }

  Future<String?> createRazorpayOrder(double amount) async 
  {
    final response = await _apiService.postRequest('/create_razorpay_order', {'amount': amount});
    if (response.statusCode == 200) 
    {
      final data = jsonDecode(response.body);
      return data['order_id'];
    }
    return null;
  }
}