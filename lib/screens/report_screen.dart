import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/expense.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';

class CategorySpendData {
  final String label;
  final double amount;
  final double percent;
  final Color color;

  const CategorySpendData({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });
}

class ReportsScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ReportsScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  static const Color navy = Color(0xFF2B2E83);

  // ---------------------------------------------------------------------------
  // MONTH NAVIGATION
  // ---------------------------------------------------------------------------

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark
            ? const Color(0xFF0F1220)
            : const Color(0xFFF8F9FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            _buildMonthSelector(isDark),

            Expanded(
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

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading reports: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.white70
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }

                  final allExpenses =
                      snapshot.data ?? [];

                  final monthlyExpenses =
                      allExpenses.where((e) {
                    return e.date.year ==
                            _selectedMonth.year &&
                        e.date.month ==
                            _selectedMonth.month;
                  }).toList();

                  // ----------------------------------------------------------------
                  // TOTAL SPENDING
                  // ----------------------------------------------------------------

                  final double totalSpent =
                      monthlyExpenses.fold(
                    0.0,
                    (sum, item) => sum + item.amount,
                  );

                  // ----------------------------------------------------------------
                  // CATEGORY TOTALS
                  // ----------------------------------------------------------------

                  final Map<String, double> categoryTotals =
                      {};

                  for (final cat
                      in AppCategory.categories) {
                    categoryTotals[cat.name] = 0.0;
                  }

                  for (final exp in monthlyExpenses) {
                    final catName =
                        exp.categoryInfo.name;

                    categoryTotals[catName] =
                        (categoryTotals[catName] ?? 0.0) +
                            exp.amount;
                  }

                  final List<CategorySpendData>
                      categoriesData =
                      AppCategory.categories.map((cat) {
                    final amount =
                        categoryTotals[cat.name] ?? 0.0;

                    final percent =
                        totalSpent > 0
                            ? (amount / totalSpent) * 100
                            : 0.0;

                    return CategorySpendData(
                      label: cat.name,
                      amount: amount,
                      percent: percent,
                      color: cat.color,
                    );
                  }).toList();

                  // Highest spending first
                  categoriesData.sort(
                    (a, b) =>
                        b.amount.compareTo(a.amount),
                  );

                  // ----------------------------------------------------------------
                  // DAILY TREND
                  // ----------------------------------------------------------------

                  final daysInMonth =
                      DateUtils.getDaysInMonth(
                    _selectedMonth.year,
                    _selectedMonth.month,
                  );

                  final List<double> dailyTrend =
                      List<double>.filled(
                    daysInMonth,
                    0.0,
                  );

                  for (final exp in monthlyExpenses) {
                    final day = exp.date.day;

                    if (day >= 1 &&
                        day <= daysInMonth) {
                      dailyTrend[day - 1] +=
                          exp.amount;
                    }
                  }

                  // ----------------------------------------------------------------
                  // CONTENT
                  // ----------------------------------------------------------------

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      80,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(
                          totalSpent,
                          categoriesData,
                          isDark,
                        ),

                        const SizedBox(height: 20),

                        _buildTrendCard(
                          dailyTrend,
                          daysInMonth,
                          isDark,
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(bool isDark) {
    final textColor =
        isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Reports',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONTH SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildMonthSelector(bool isDark) {
    final monthStr =
        DateFormat('MMMM yyyy').format(_selectedMonth);

    final cardColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final secondaryColor =
        isDark ? Colors.white60 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.20 : 0.04,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(
                Icons.chevron_left,
                size: 20,
                color: secondaryColor,
              ),
              visualDensity:
                  VisualDensity.compact,
            ),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: navy,
                ),

                const SizedBox(width: 8),

                Text(
                  monthStr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
              ],
            ),

            IconButton(
              onPressed: _nextMonth,
              icon: Icon(
                Icons.chevron_right,
                size: 20,
                color: secondaryColor,
              ),
              visualDensity:
                  VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY CARD
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(
    double totalSpent,
    List<CategorySpendData> categories,
    bool isDark,
  ) {
    final currency =
        AppState.instance.currencySymbol;

    final cardColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final primaryText =
        isDark ? Colors.white : Colors.black87;

    final secondaryText =
        isDark ? Colors.white60 : Colors.black45;

    final emptyIconColor =
        isDark ? Colors.white30 : Colors.black26;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.20 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Expenses',
            style: TextStyle(
              fontSize: 13,
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$currency${totalSpent.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 16),

          if (totalSpent > 0) ...[
            Center(
              child: SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    categories: categories,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          'Total spent',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '$currency${totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ...categories
                .where(
                  (c) =>
                      c.amount > 0 ||
                      categories.indexOf(c) < 5,
                )
                .map(
                  (c) => _buildLegendRow(
                    c,
                    isDark,
                  ),
                ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 36,
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 56,
                    color: emptyIconColor,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'No expenses recorded for this month',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEGEND ROW
  // ---------------------------------------------------------------------------

  Widget _buildLegendRow(
    CategorySpendData c,
    bool isDark,
  ) {
    final currency =
        AppState.instance.currencySymbol;

    final primaryText =
        isDark ? Colors.white : Colors.black87;

    final secondaryText =
        isDark ? Colors.white60 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c.color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              c.label,
              style: TextStyle(
                fontSize: 14,
                color: primaryText,
              ),
            ),
          ),

          Text(
            '$currency${c.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 36,
            child: Text(
              '${c.percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TREND CARD
  // ---------------------------------------------------------------------------

  Widget _buildTrendCard(
    List<double> dailyTrend,
    int daysInMonth,
    bool isDark,
  ) {
    final monthStr =
        DateFormat('MMMM yyyy').format(_selectedMonth);

    final hasData =
        dailyTrend.any((val) => val > 0);

    final cardColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final primaryText =
        isDark ? Colors.white : Colors.black87;

    final secondaryText =
        isDark ? Colors.white60 : Colors.black45;

    final axisText =
        isDark ? Colors.white38 : Colors.black38;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.20 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Daily spending throughout $monthStr',
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 16),

          if (hasData) ...[
            SizedBox(
              height: 90,
              child: CustomPaint(
                size: const Size(
                  double.infinity,
                  90,
                ),
                painter: _TrendBarPainter(
                  values: dailyTrend,
                  color: navy,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1',
                  style: TextStyle(
                    fontSize: 11,
                    color: axisText,
                  ),
                ),

                Text(
                  '10',
                  style: TextStyle(
                    fontSize: 11,
                    color: axisText,
                  ),
                ),

                Text(
                  '20',
                  style: TextStyle(
                    fontSize: 11,
                    color: axisText,
                  ),
                ),

                Text(
                  '$daysInMonth',
                  style: TextStyle(
                    fontSize: 11,
                    color: axisText,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 24,
              ),
              alignment: Alignment.center,
              child: Text(
                'No trend data available for this month',
                style: TextStyle(
                  color: axisText,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// DONUT CHART PAINTER
// =============================================================================

class _DonutChartPainter extends CustomPainter {
  final List<CategorySpendData> categories;

  _DonutChartPainter({
    required this.categories,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(size.width, size.height) / 2;

    const strokeWidth = 26.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;

    const gapDegrees = 3.0;

    final gapRadians =
        gapDegrees * math.pi / 180;

    final nonZero =
        categories
            .where((c) => c.percent > 0)
            .toList();

    if (nonZero.isEmpty) {
      return;
    }

    for (final c in nonZero) {
      final sweep =
          (c.percent / 100) *
              2 *
              math.pi;

      final paint = Paint()
        ..color = c.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final adjustedSweep =
          nonZero.length > 1
              ? math.max(
                  sweep - gapRadians,
                  0.01,
                )
              : sweep;

      canvas.drawArc(
        rect,
        startAngle,
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant _DonutChartPainter oldDelegate,
  ) {
    return true;
  }
}

// =============================================================================
// TREND BAR PAINTER
// =============================================================================

class _TrendBarPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _TrendBarPainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (values.isEmpty) {
      return;
    }

    final maxVal = values.reduce(math.max);

    final barCount = values.length;

    const gap = 3.0;

    final barWidth =
        (size.width -
                gap * (barCount - 1)) /
            barCount;

    final barPaint = Paint()
      ..color = color;

    final dotPaint = Paint()
      ..color = color.withValues(
        alpha: 0.25,
      );

    for (int i = 0;
        i < barCount;
        i++) {
      final v = values[i];

      final normalized =
          maxVal == 0
              ? 0.0
              : v / maxVal;

      final barHeight =
          math.max(
        normalized * size.height,
        4.0,
      );

      final left =
          i * (barWidth + gap);

      final top =
          size.height - barHeight;

      if (v == 0) {
        canvas.drawCircle(
          Offset(
            left + barWidth / 2,
            size.height - 3,
          ),
          1.8,
          dotPaint,
        );
      } else {
        final rrect =
            RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            top,
            barWidth,
            barHeight,
          ),
          const Radius.circular(2),
        );

        canvas.drawRRect(
          rrect,
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _TrendBarPainter oldDelegate,
  ) {
    return true;
  }
}