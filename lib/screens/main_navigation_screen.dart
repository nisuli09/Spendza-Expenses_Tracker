import 'package:flutter/material.dart';

import 'add_expenses_screen.dart';
import 'expenses_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 0: Home
  // 1: Expenses
  // 2: Reports
  // 3: Profile
  int _selectedTabIndex = 0;

  static const Color navy = Color(0xFF2B2E83);
  static const Color darkBackground = Color(0xFF121426);

  void _navigateToTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeScreen(
        onNavigateToTab: _navigateToTab,
      ),
      ExpensesScreen(
        onNavigateToTab: _navigateToTab,
      ),
      ReportsScreen(
        onNavigateToTab: _navigateToTab,
      ),
      ProfileScreen(
        onNavigateToTab: _navigateToTab,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedTabIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    final Color backgroundColor =
        isDark ? darkBackground : Colors.white;

    final Color unselectedColor =
        isDark ? Colors.white70 : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        border: isDark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.home_rounded,
              label: 'Home',
              tabIndex: 0,
              unselectedColor: unselectedColor,
            ),
            _navItem(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              tabIndex: 1,
              unselectedColor: unselectedColor,
            ),
            _buildCenterAddButton(isDark),
            _navItem(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              tabIndex: 2,
              unselectedColor: unselectedColor,
            ),
            _navItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              tabIndex: 3,
              unselectedColor: unselectedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int tabIndex,
    required Color unselectedColor,
  }) {
    final bool selected = _selectedTabIndex == tabIndex;

    final Color color = selected ? navy : unselectedColor;

    return InkWell(
      onTap: () => _navigateToTab(tabIndex),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(bool isDark) {
    return InkWell(
      onTap: _openAddExpense,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: navy,
          shape: BoxShape.circle,
          border: isDark
              ? Border.all(
                  color: Colors.white,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: navy.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}