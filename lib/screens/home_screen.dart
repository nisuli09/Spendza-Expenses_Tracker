import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/expense.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import 'add_expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color navy = Color(0xFF2E3A8C);

  void _openAddExpense([Expense? expense]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(expenseToEdit: expense),
      ),
    );
  }

  void _showNotificationsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg =
        isDark ? const Color(0xFF1E2138) : Colors.white;

    final textColor =
        isDark ? Colors.white : const Color(0xFF191C32);

    final subTextColor =
        isDark ? Colors.white70 : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: navy,
            ),
            const SizedBox(width: 8),
            Text(
              'Notifications',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Welcome to Spendza!',
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              '• All your expenses sync in real-time with Firebase Cloud Firestore.',
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              '• You can view charts in Reports or manage your settings in Profile.',
              style: TextStyle(color: subTextColor),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: FirestoreService().getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: navy,
                ),
              );
            }

            final allExpenses = snapshot.data ?? [];

            // Filter for current month
            final currentMonthExpenses =
                allExpenses.where((e) {
              return e.date.year == now.year &&
                  e.date.month == now.month;
            }).toList();

            final double totalMonthSpend =
                currentMonthExpenses.fold(
              0.0,
              (sum, item) => sum + item.amount,
            );

            final int count = currentMonthExpenses.length;
            final int dayOfMonth =
                now.day > 0 ? now.day : 1;

            final double dailyAverage =
                totalMonthSpend > 0
                    ? (totalMonthSpend / dayOfMonth)
                    : 0.0;

            // Category breakdown
            final Map<String, double> categorySums = {};

            for (final exp in currentMonthExpenses) {
              final cat = exp.categoryInfo.name;
              categorySums[cat] =
                  (categorySums[cat] ?? 0.0) + exp.amount;
            }

            // Top category
            String topCategoryName = 'None';
            double topCategoryAmount = 0.0;
            AppCategory topCategory =
                AppCategory.categories.first;

            categorySums.forEach((catName, sum) {
              if (sum > topCategoryAmount) {
                topCategoryAmount = sum;
                topCategoryName = catName;
                topCategory =
                    AppCategory.fromName(catName);
              }
            });

            // Recent 5 expenses
            final recentExpenses =
                allExpenses.take(5).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 18),

                  _buildTotalExpensesCard(
                    monthStr,
                    totalMonthSpend,
                  ),

                  const SizedBox(height: 16),

                  _buildQuickStatsRow(
                    count: count,
                    dailyAverage: dailyAverage,
                    topCategoryName: topCategoryName,
                    topCategory: topCategory,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Spending by Category',
                    actionLabel: 'See reports',
                    onAction: () =>
                        widget.onNavigateToTab?.call(2),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  _buildCategoryList(
                    categorySums,
                    totalMonthSpend,
                    isDark,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    'Recent Expenses',
                    actionLabel: 'See all',
                    onAction: () =>
                        widget.onNavigateToTab?.call(1),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  _buildRecentExpensesList(
                    recentExpenses,
                    isDark,
                  ),

                  const SizedBox(height: 24),

                  _buildAddExpenseButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _buildHeader(bool isDark) {
    final app = AppState.instance;

    final initial = app.userName.isNotEmpty
        ? app.userName[0].toUpperCase()
        : 'A';

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final subTextColor =
        isDark ? Colors.white60 : Colors.grey;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning!',
              style: TextStyle(
                fontSize: 13,
                color: subTextColor,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              'Hello, ${app.userName}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),

        Row(
          children: [
            _circleIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: _showNotificationsDialog,
              isDark: isDark,
            ),

            const SizedBox(width: 10),

            InkWell(
              onTap: () =>
                  widget.onNavigateToTab?.call(3),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 20,
                backgroundColor:
                    isDark
                        ? const Color(0xFF35294D)
                        : const Color(0xFFEDE1FF),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF8A4FE0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2138)
              : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.2 : 0.05,
              ),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark
              ? Colors.white70
              : Colors.black54,
          size: 22,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Total expenses card
  // -------------------------------------------------------------------------

  Widget _buildTotalExpensesCard(
    String monthStr,
    double totalSpend,
  ) {
    final currency =
        AppState.instance.currencySymbol;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E3A8C),
            Color(0xFF39469E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3A8C)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthStr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            'Total Expenses',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$currency${totalSpend.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Your spending this month',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Quick stats row
  // -------------------------------------------------------------------------

  Widget _buildQuickStatsRow({
    required int count,
    required double dailyAverage,
    required String topCategoryName,
    required AppCategory topCategory,
    required bool isDark,
  }) {
    final currency =
        AppState.instance.currencySymbol;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.receipt_long,
            iconColor: const Color(0xFF4E7DF0),
            iconBg: isDark
                ? const Color(0xFF26365F)
                : const Color(0xFFE7EEFF),
            value: '$count',
            label: 'Expenses',
            isDark: isDark,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.show_chart,
            iconColor: const Color(0xFF2ED9A3),
            iconBg: isDark
                ? const Color(0xFF183E36)
                : const Color(0xFFE1FBF2),
            value:
                '$currency${dailyAverage.toStringAsFixed(2)}',
            label: 'Daily average',
            isDark: isDark,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: topCategory.icon,
            iconColor: topCategory.color,
            iconBg: isDark
                ? topCategory.color.withValues(
                    alpha: 0.15,
                  )
                : topCategory.iconBg,
            value: topCategoryName,
            label: 'Top category',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required bool isDark,
  }) {
    final cardBg =
        isDark ? const Color(0xFF1E2138) : Colors.white;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final subTextColor =
        isDark ? Colors.white60 : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section header
  // -------------------------------------------------------------------------

  Widget _buildSectionHeader(
    String title, {
    required String actionLabel,
    required VoidCallback onAction,
    required bool isDark,
  }) {
    final textColor =
        isDark ? Colors.white : Colors.black87;

    final subTextColor =
        isDark ? Colors.white60 : Colors.grey;

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),

        InkWell(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios,
                size: 11,
                color: subTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Category list with progress bars
  // -------------------------------------------------------------------------

  Widget _buildCategoryList(
    Map<String, double> categorySums,
    double totalSpend,
    bool isDark,
  ) {
    final currency =
        AppState.instance.currencySymbol;

    final categories =
        AppCategory.categories.where((cat) {
      return (categorySums[cat.name] ?? 0) > 0;
    }).toList();

    final cardBg =
        isDark ? const Color(0xFF1E2138) : Colors.white;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final subTextColor =
        isDark ? Colors.white60 : Colors.grey;

    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No category expenses this month yet.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: categories.map((cat) {
          final amount =
              categorySums[cat.name] ?? 0.0;

          final progress = totalSpend > 0
              ? (amount / totalSpend)
                  .clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(
                            color: cat.color,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                    Text(
                      '$currency${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(6),
                  child:
                      LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF30334A)
                        : const Color(0xFFF0F0F5),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      cat.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Recent expenses list
  // -------------------------------------------------------------------------

  Widget _buildRecentExpensesList(
    List<Expense> expenses,
    bool isDark,
  ) {
    final cardBg =
        isDark ? const Color(0xFF1E2138) : Colors.white;

    final subTextColor =
        isDark ? Colors.white60 : Colors.grey;

    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No expenses recorded yet.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 12,
      ),
      child: Column(
        children: expenses
            .map(
              (e) => _expenseRow(
                e,
                isDark,
              ),
            )
            .expand(
              (w) => [
                w,
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white12
                      : Colors.black12,
                ),
              ],
            )
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _expenseRow(
    Expense e,
    bool isDark,
  ) {
    final currency =
        AppState.instance.currencySymbol;

    final cat = e.categoryInfo;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final subTextColor =
        isDark ? Colors.white60 : Colors.grey;

    return InkWell(
      onTap: () => _openAddExpense(e),
      borderRadius:
          BorderRadius.circular(12),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? cat.color.withValues(
                        alpha: 0.15,
                      )
                    : cat.iconBg,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                cat.icon,
                color: cat.color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '${e.category} · ${DateFormat('MMM d').format(e.date)}${e.note.isNotEmpty ? ' · ${e.note}' : ''}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              '-$currency${e.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8543E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Add expense button
  // -------------------------------------------------------------------------

  Widget _buildAddExpenseButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openAddExpense(),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}