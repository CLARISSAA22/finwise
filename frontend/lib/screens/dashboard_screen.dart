import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'home_tab.dart';
import 'add_transaction_screen.dart';
import 'budgets_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'wealth_tab.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'goals_screen.dart';
import 'subscriptions_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget 
        {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> 
{
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomeTab(),
    const BudgetsScreen(),
    const WealthTab(),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

//loading page 
  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinWise', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primary, size: 40),
              ),
              accountName: const Text('FinWise User', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('user@finwise.com'),
            ),// transcation //
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              title: const Text('New Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () 
              {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (c) => const AddTransactionScreen()));
              },
            ),
            //budget//
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pie_chart_outline, color: Colors.grey),
              title: const Text('Budgets'),
              onTap: ()
              {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),//profile//
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              },
            ),//logout//
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => const AddTransactionScreen()));
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
            _buildNavItem(1, Icons.pie_chart_outline, Icons.pie_chart, 'Budgets'),
            _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Wealth'),
            _buildNavItem(3, Icons.insights, Icons.insights, 'Insights'),
            _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primary : Colors.grey, size: 26),
          Text(label, style: TextStyle(color: isActive ? AppColors.primary : Colors.grey, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}