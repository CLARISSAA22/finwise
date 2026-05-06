import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../utils/constants.dart';
import 'goals_screen.dart';
import 'subscriptions_screen.dart';
import 'package:flutter/cupertino.dart';

class WealthTab extends StatefulWidget {
  const WealthTab({super.key});

  @override
  State<WealthTab> createState() => _WealthTabState();
}

class _WealthTabState extends State<WealthTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fp = Provider.of<FinanceProvider>(context, listen: false);
      fp.fetchGoals();
      fp.fetchSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wealth', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Savings Goals', () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => GoalsScreen()));
            }),
            const SizedBox(height: 12),
            if (fp.goals.isEmpty)
              _buildEmptyState('No active goals. Start saving today!', Icons.flag_outlined)
            else
              ...fp.goals.take(2).map((g) => _buildGoalCard(g)),
            
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Subscriptions', () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const SubscriptionsScreen()));
            }),
            const SizedBox(height: 12),
            if (fp.subscriptions.isEmpty)
              _buildEmptyState('No subscriptions added.', Icons.subscriptions_outlined)
            else
              ...fp.subscriptions.take(2).map((s) => _buildSubscriptionCard(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        TextButton(onPressed: onTap, child: const Text('View All')),
      ],
    );
  }

  Widget _buildGoalCard(dynamic goal) {
    double progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppColors.borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppColors.borderRadius,
          boxShadow: AppColors.shadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}', 
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryLight,
              color: AppColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(dynamic sub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppColors.borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppColors.borderRadius,
          boxShadow: AppColors.shadow,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: sub.isDueSoon ? AppColors.accent.withOpacity(0.1) : AppColors.secondaryLight,
            child: Icon(Icons.calendar_today, color: sub.isDueSoon ? AppColors.accent : AppColors.secondary, size: 20),
          ),
          title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Due in ${sub.dueInDays} days'),
          trailing: Text('₹${sub.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppColors.borderRadius,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}