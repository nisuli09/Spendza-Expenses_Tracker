import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/expense.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import 'add_expenses_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ExpensesScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _selectedFilter = 0;

  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  bool _isSearching = false;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  static const Color navy = Color(0xFF2B2E83);
  static const Color danger = Color(0xFFE0555D);

  final List<String> _filters = [
    'All',
    ...AppCategory.categories.map((c) => c.name),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
  // ADD / EDIT EXPENSE
  // ---------------------------------------------------------------------------

  void _openAddExpense([Expense? expense]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          expenseToEdit: expense,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPENSE OPTIONS
  // ---------------------------------------------------------------------------

  void _showExpenseOptions(Expense expense) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final sheetColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final primaryText =
        isDark ? Colors.white : Colors.black87;

    final secondaryText =
        isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white24
                            : Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(2),
                  ),
                ),

                // Expense information
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          expense
                              .categoryInfo
                              .iconBg,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Icon(
                      expense.categoryInfo.icon,
                      color:
                          expense.categoryInfo.color,
                      size: 20,
                    ),
                  ),

                  title: Text(
                    expense.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryText,
                    ),
                  ),

                  subtitle: Text(
                    '${expense.formattedDate} · '
                    '${AppState.instance.currencySymbol}'
                    '${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: secondaryText,
                    ),
                  ),
                ),

                Divider(
                  color:
                      isDark
                          ? Colors.white12
                          : Colors.black12,
                ),

                // Edit
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: navy,
                  ),
                  title: Text(
                    'Edit Expense',
                    style: TextStyle(
                      color: primaryText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAddExpense(expense);
                  },
                ),

                // Delete
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: danger,
                  ),
                  title: const Text(
                    'Delete Expense',
                    style: TextStyle(
                      color: danger,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);

                    final confirm =
                        await showDialog<bool>(
                      context: context,
                      builder: (dCtx) {
                        return AlertDialog(
                          backgroundColor:
                              isDark
                                  ? const Color(
                                      0xFF1E2235,
                                    )
                                  : Colors.white,
                          surfaceTintColor:
                              Colors.transparent,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          title: Text(
                            'Delete Expense',
                            style: TextStyle(
                              color: primaryText,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete '
                            '"${expense.title}"?',
                            style: TextStyle(
                              color: secondaryText,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(
                                dCtx,
                                false,
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.white60
                                          : Colors.grey,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    danger,
                                foregroundColor:
                                    Colors.white,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.pop(
                                dCtx,
                                true,
                              ),
                              child:
                                  const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      try {
                        await FirestoreService()
                            .deleteExpense(
                          expense.id,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Expense deleted',
                              ),
                              backgroundColor:
                                  danger,
                              behavior:
                                  SnackBarBehavior
                                      .floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error deleting expense: $e',
                              ),
                              backgroundColor:
                                  danger,
                              behavior:
                                  SnackBarBehavior
                                      .floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DATE GROUP
  // ---------------------------------------------------------------------------

  String _getDateGroupLabel(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday = DateTime(
      now.year,
      now.month,
      now.day - 1,
    );

    final expenseDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (expenseDay == today) {
      return 'TODAY';
    } else if (expenseDay == yesterday) {
      return 'YESTERDAY';
    } else {
      return DateFormat(
        'EEEE, MMM d',
      ).format(date).toUpperCase();
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

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

            if (_isSearching)
              _buildSearchBar(isDark),

            _buildMonthSelector(isDark),

            _buildFilterChips(isDark),

            Expanded(
              child: _buildExpensesStream(isDark),
            ),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () => _openAddExpense(),
        backgroundColor: navy,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
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

    final iconColor =
        isDark ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Expenses',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching =
                        !_isSearching;

                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
                icon: Icon(
                  _isSearching
                      ? Icons.close
                      : Icons.search,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH BAR
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(bool isDark) {
    final cardColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final borderColor =
        isDark
            ? const Color(0xFF34394F)
            : const Color(0xFFE6E6EC);

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final hintColor =
        isDark ? Colors.white38 : Colors.black38;

    final iconColor =
        isDark ? Colors.white54 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,

        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),

        cursorColor: navy,

        decoration: InputDecoration(
          hintText:
              'Search by title, note, or category...',

          hintStyle: TextStyle(
            fontSize: 14,
            color: hintColor,
          ),

          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: iconColor,
          ),

          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: iconColor,
                      ),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,

          filled: true,
          fillColor: cardColor,

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide(
              color: borderColor,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide(
              color: borderColor,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: navy,
              width: 1.5,
            ),
          ),
        ),

        onChanged: (val) {
          setState(() {
            _searchQuery =
                val.trim().toLowerCase();
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONTH SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildMonthSelector(bool isDark) {
    final monthStr =
        DateFormat('MMMM yyyy')
            .format(_selectedMonth);

    final cardColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final textColor =
        isDark ? Colors.white : Colors.black87;

    final iconColor =
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
          borderRadius:
              BorderRadius.circular(14),
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
                color: iconColor,
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
                    fontWeight:
                        FontWeight.w600,
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
                color: iconColor,
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
  // FILTER CHIPS
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips(bool isDark) {
    final unselectedText =
        isDark ? Colors.white70 : Colors.black87;

    final borderColor =
        isDark
            ? const Color(0xFF34394F)
            : const Color(0xFFE0E0E0);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,

        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),

        itemBuilder: (context, index) {
          final bool selected =
              index == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },

            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color:
                    selected
                        ? navy
                        : isDark
                            ? const Color(
                                0xFF1E2235,
                              )
                            : Colors.white,

                borderRadius:
                    BorderRadius.circular(20),

                border: Border.all(
                  color:
                      selected
                          ? Colors.transparent
                          : borderColor,
                ),
              ),

              alignment: Alignment.center,

              child: Text(
                _filters[index],
                style: TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : unselectedText,
                  fontWeight:
                      FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPENSE STREAM
  // ---------------------------------------------------------------------------

  Widget _buildExpensesStream(bool isDark) {
    return StreamBuilder<List<Expense>>(
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
          debugPrint(
            'Expenses error: ${snapshot.error}',
          );

          return _buildNoDataErrorState(isDark);
        }

        final allExpenses =
            snapshot.data ?? [];

        // ---------------------------------------------------------------
        // 1. FILTER BY MONTH
        // ---------------------------------------------------------------

        final filteredByMonth =
            allExpenses.where((e) {
          return e.date.year ==
                  _selectedMonth.year &&
              e.date.month ==
                  _selectedMonth.month;
        }).toList();

        // ---------------------------------------------------------------
        // 2. FILTER BY CATEGORY
        // ---------------------------------------------------------------

        final selectedCatName =
            _filters[_selectedFilter];

        final filteredByCategory =
            selectedCatName == 'All'
                ? filteredByMonth
                : filteredByMonth
                    .where(
                      (e) =>
                          e.category
                              .toLowerCase() ==
                          selectedCatName
                              .toLowerCase(),
                    )
                    .toList();

        // ---------------------------------------------------------------
        // 3. FILTER BY SEARCH
        // ---------------------------------------------------------------

        final finalExpenses =
            _searchQuery.isEmpty
                ? filteredByCategory
                : filteredByCategory
                    .where((e) {
                      return e.title
                              .toLowerCase()
                              .contains(
                                _searchQuery,
                              ) ||
                          e.note
                              .toLowerCase()
                              .contains(
                                _searchQuery,
                              ) ||
                          e.category
                              .toLowerCase()
                              .contains(
                                _searchQuery,
                              );
                    })
                    .toList();

        if (finalExpenses.isEmpty) {
          return _buildEmptyState(isDark);
        }

        // ---------------------------------------------------------------
        // GROUP BY DATE
        // ---------------------------------------------------------------

        final Map<String, List<Expense>>
            grouped = {};

        for (final exp in finalExpenses) {
          final label =
              _getDateGroupLabel(exp.date);

          grouped
              .putIfAbsent(
                label,
                () => [],
              )
              .add(exp);
        }

        final groupKeys =
            grouped.keys.toList();

        return ListView.builder(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            80,
          ),

          itemCount: groupKeys.length,

          itemBuilder:
              (context, groupIndex) {
            final groupLabel =
                groupKeys[groupIndex];

            final items =
                grouped[groupLabel]!;

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 14,
                    bottom: 8,
                  ),
                  child: Text(
                    groupLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          isDark
                              ? Colors.white54
                              : Colors.black45,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                ...items.map(
                  (expense) =>
                      _buildExpenseTile(
                    expense,
                    isDark,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // NO DATA / ERROR STATE
  // ---------------------------------------------------------------------------

  Widget _buildNoDataErrorState(bool isDark) {
    final iconColor =
        isDark ? Colors.white30 : Colors.black26;

    final textColor =
        isDark ? Colors.white54 : Colors.black45;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: iconColor,
            ),

            const SizedBox(height: 12),

            Text(
              'No available data',
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(bool isDark) {
    final monthStr =
        DateFormat('MMMM yyyy')
            .format(_selectedMonth);

    final primaryText =
        isDark ? Colors.white : Colors.black87;

    final secondaryText =
        isDark ? Colors.white54 : Colors.black45;

    final iconBackground =
        isDark
            ? const Color(0xFF252B4A)
            : const Color(0xFFE7EEFF);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: navy,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching expenses'
                  : 'No expenses for $monthStr',

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching for something else'
                  : 'Tap the button below to add your first expense',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () =>
                  _openAddExpense(),

              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),

              label: const Text(
                'Add Expense',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor: navy,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPENSE TILE
  // ---------------------------------------------------------------------------

  Widget _buildExpenseTile(
    Expense expense,
    bool isDark,
  ) {
    final currencySymbol =
        AppState.instance.currencySymbol;

    final cat = expense.categoryInfo;

    final cardColor =
        isDark
            ? const Color(0xFF1E2235)
            : Colors.white;

    final primaryText =
        isDark ? Colors.white : Colors.black87;

    final secondaryText =
        isDark ? Colors.white54 : Colors.black45;

    final moreIconColor =
        isDark ? Colors.white30 : Colors.black26;

    return InkWell(
      onTap: () =>
          _openAddExpense(expense),

      borderRadius:
          BorderRadius.circular(16),

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: cardColor,

          borderRadius:
              BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.20 : 0.03,
              ),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            // -------------------------------------------------------------
            // CATEGORY ICON
            // -------------------------------------------------------------

            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: cat.iconBg,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Icon(
                cat.icon,
                color: cat.color,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // -------------------------------------------------------------
            // TITLE + DETAILS
            // -------------------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,

                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      fontSize: 14,
                      color: primaryText,
                    ),

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  Text(
                    '${expense.category} · '
                    '${DateFormat('MMM d').format(expense.date)}'
                    '${expense.note.isNotEmpty ? ' · ${expense.note}' : ''}',

                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryText,
                    ),

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // -------------------------------------------------------------
            // AMOUNT
            // -------------------------------------------------------------

            Text(
              '-$currencySymbol'
              '${expense.amount.toStringAsFixed(2)}',

              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 14,
                color: danger,
              ),
            ),

            const SizedBox(width: 8),

            // -------------------------------------------------------------
            // MORE BUTTON
            // -------------------------------------------------------------

            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: moreIconColor,
                size: 20,
              ),

              onPressed: () =>
                  _showExpenseOptions(
                expense,
              ),

              padding: EdgeInsets.zero,

              constraints:
                  const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}