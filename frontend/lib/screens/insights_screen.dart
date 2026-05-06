import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';
import '../utils/constants.dart';
import '../models/models.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<FinanceProvider>(context);
    final insights = fp.insights;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Financial Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: insights.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(insights),
    );
  }

  Widget _buildBody(Map<String, dynamic> insights) {
    final double score = insights['health_score'] != null ? double.parse(insights['health_score'].toString()) : 0.0;
    final categoryInsights = insights['category_insights'] as List? ?? [];
    final double currentSpent = double.parse(insights['current_month_spent']?.toString() ?? '0');
    final double lastSpent = double.parse(insights['last_month_spent']?.toString() ?? '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthScoreCard(score, insights['saving_tip'] ?? ''),
          const SizedBox(height: 32),
          const Text('Income vs Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _buildComparativeBarChart(currentSpent, lastSpent),
          const SizedBox(height: 32),
          const Text('Spending by Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _buildCategoryPieChart(),
          const SizedBox(height: 32),
          const Text('Spending by Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          _buildPaymentMethodStats(insights['payment_method_spending'] ?? {}),
          const SizedBox(height: 32),
          const Text('AI Observations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          if (categoryInsights.isEmpty && (insights['mood_insight'] == null || insights['mood_insight'] == ""))
            _buildInsightCard('Analyzing your data...', 'Keep tracking to see patterns.', Icons.info_outline, Colors.blueGrey)
          else ...[
            ...categoryInsights.map((ci) => _buildInsightCard('Spending Pattern', ci.toString(), Icons.trending_up, AppColors.accent)),
            if (insights['mood_insight'] != null && insights['mood_insight'] != "")
              _buildInsightCard('Mood Connection', insights['mood_insight'], Icons.mood, AppColors.primary),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(double score, String tip) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppColors.borderRadius,
        boxShadow: AppColors.shadow,
      ),
      child: Column(
        children: [
          const Text('Financial Health Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    startDegreeOffset: 270,
                    sections: [
                      PieChartSectionData(
                          color: score >= 80 ? AppColors.secondary : (score >= 50 ? Colors.orange : AppColors.accent),
                          value: score,
                          title: '',
                          radius: 15),
                      PieChartSectionData(color: AppColors.primaryLight, value: 100 - score, title: '', radius: 10)
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${score.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text(score >= 80 ? 'Excellent' : (score >= 50 ? 'Good' : 'Needs Work'),
                        style: TextStyle(color: score >= 80 ? AppColors.secondary : (score >= 50 ? Colors.orange : AppColors.accent), fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: Text(tip, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textDark, fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativeBarChart(double currentSpent, double lastSpent) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppColors.borderRadius, boxShadow: AppColors.shadow),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (currentSpent > lastSpent ? currentSpent : lastSpent) * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12);
                  return SideTitleWidget(
                    axisSide: meta.axisSide, 
                    space: 8,
                    fitInside: SideTitleFitInsideData(
                      enabled: true,
                      distanceFromEdge: 0,
                      parentAxisSize: meta.parentAxisSize,
                      axisPosition: meta.axisPosition,
                    ),
                    child: Text(value == 0 ? 'Last Month' : 'This Month', style: style),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: lastSpent, color: Colors.grey.shade400, width: 40, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: currentSpent, color: AppColors.primary, width: 40, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final fp = Provider.of<FinanceProvider>(context, listen: false);
    final txs = fp.transactions.where((t) => t.type == 'expense').toList();
    if (txs.isEmpty) return const Center(child: Text('No expense data available.'));

    Map<String, double> catMap = {};
    for (var tx in txs) {
      catMap[tx.category] = (catMap[tx.category] ?? 0) + tx.amount;
    }

    final sortedItems = catMap.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final topItems = sortedItems.take(5).toList();

    List<Color> colors = [Colors.teal, Colors.indigo, Colors.orange, Colors.purple, Colors.red];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppColors.borderRadius, boxShadow: AppColors.shadow),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: topItems.asMap().entries.map((e) {
                  return PieChartSectionData(color: colors[e.key % colors.length], value: e.value.value, title: '', radius: 40);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...topItems.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(e.value.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('₹${e.value.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }


  Widget _buildPaymentMethodStats(Map<String, dynamic> pmStats) {
    if (pmStats.isEmpty) return const SizedBox.shrink();
    
    double upi = double.tryParse(pmStats['UPI']?.toString() ?? '0') ?? 0;
    double card = double.tryParse(pmStats['Card']?.toString() ?? '0') ?? 0;
    double cash = double.tryParse(pmStats['Cash']?.toString() ?? '0') ?? 0;
    double total = upi + card + cash;
    if (total == 0) total = 1;

    return Column(
      children: [
        if (total > 1)
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  if (upi > 0) PieChartSectionData(color: Colors.teal, value: upi, title: '${(upi/total*100).toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (card > 0) PieChartSectionData(color: Colors.orange, value: card, title: '${(card/total*100).toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (cash > 0) PieChartSectionData(color: Colors.blueGrey, value: cash, title: '${(cash/total*100).toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ]
              )
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildPMCard('UPI', pmStats['UPI'] ?? 0, Icons.qr_code, Colors.teal),
            const SizedBox(width: 12),
            _buildPMCard('Card', pmStats['Card'] ?? 0, Icons.credit_card, Colors.orange),
            const SizedBox(width: 12),
            _buildPMCard('Cash', pmStats['Cash'] ?? 0, Icons.money, Colors.blueGrey),
          ],
        ),
      ],
    );
  }

  Widget _buildPMCard(String label, dynamic amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppColors.borderRadius,
          boxShadow: AppColors.shadow,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight)),
            const SizedBox(height: 4),
            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(double score) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }

  Widget _buildInsightCard(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppColors.borderRadius,
        boxShadow: AppColors.shadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
