import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/expense.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  String? _selectedCategory;
  bool _isLoading = false;

  static const Color _navy = Color(0xFF2B2E83);
  static const Color _danger = Color(0xFFE0555D);
  static const Color _success = Color(0xFF17A883);

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final exp = widget.expenseToEdit!;

      _titleController.text = exp.title;
      _amountController.text = exp.amount.toStringAsFixed(2);
      _noteController.text = exp.note;
      _selectedDate = exp.date;
      _selectedCategory = exp.category;
    } else {
      _selectedDate = DateTime.now();
      _selectedCategory = 'Food';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: _navy,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E2235),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: _navy,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String get _formattedDate =>
      DateFormat('dd/MM/yyyy').format(_selectedDate);

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final amount =
        double.tryParse(_amountController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();
    final category = _selectedCategory ?? 'Other';

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        final updatedExpense = widget.expenseToEdit!.copyWith(
          title: title,
          amount: amount,
          category: category,
          date: _selectedDate,
          note: note,
        );

        await FirestoreService().updateExpense(updatedExpense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
              backgroundColor: _success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, true);
        }
      } else {
        final newExpense = Expense(
          id: '',
          title: title,
          amount: amount,
          category: category,
          date: _selectedDate,
          note: note,
        );

        await FirestoreService().addExpense(newExpense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully'),
              backgroundColor: _success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF1E2235) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Expense',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this expense?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirestoreService()
            .deleteExpense(widget.expenseToEdit!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted'),
              backgroundColor: _danger,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting expense: $e'),
              backgroundColor: _danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF0F1220) : const Color(0xFFF8F9FC);

    final cardBg =
        isDark ? const Color(0xFF1E2235) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(
                        'Expense Title',
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: 8),
                      _buildTitleField(cardBg, isDark),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Amount',
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: 8),
                      _buildAmountField(cardBg, isDark),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Category',
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: 8),
                      _buildCategoryDropdown(cardBg, isDark),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Date',
                        isDark: isDark,
                        required: true,
                      ),
                      const SizedBox(height: 8),
                      _buildDateField(cardBg, isDark),

                      const SizedBox(height: 20),

                      _buildLabel(
                        'Note',
                        isDark: isDark,
                        optionalText: '(optional)',
                      ),
                      const SizedBox(height: 8),
                      _buildNoteField(cardBg, isDark),

                      const SizedBox(height: 28),

                      _buildSaveButton(),

                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        _buildDeleteButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // APP BAR
  // -------------------------------------------------------------
  
  Widget _buildAppBar(bool isDark) {
    final textColor =
        isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: textColor,
                ),
              ),
              Text(
                _isEditing ? 'Edit Expense' : 'Add Expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),

          if (_isEditing)
            IconButton(
              onPressed: _isLoading ? null : _confirmDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: _danger,
              ),
              tooltip: 'Delete expense',
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LABEL
  // -------------------------------------------------------------
  
  Widget _buildLabel(
    String text, {
    bool required = false,
    String? optionalText,
    required bool isDark,
  }) {
    final textColor =
        isDark ? Colors.white : Colors.black87;

    final optionalColor =
        isDark ? Colors.white38 : Colors.black38;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        children: [
          TextSpan(text: text),

          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: _danger,
              ),
            ),

          if (optionalText != null)
            TextSpan(
              text: ' $optionalText',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: optionalColor,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FIELD DECORATION
  // -------------------------------------------------------------

  InputDecoration _fieldDecoration({
    String? hint,
    Widget? prefix,
    Widget? suffix,
    required Color fillColor,
    required bool isDark,
  }) {
    final textColor =
        isDark ? Colors.white : Colors.black87;

    final hintColor =
        isDark ? Colors.white38 : Colors.black26;

    final borderColor =
        isDark
            ? const Color(0xFF34394F)
            : const Color(0xFFE6E6EC);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 15,
      ),

      prefixIcon: prefix,
      suffixIcon: suffix,

      filled: true,
      fillColor: fillColor,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _navy,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _danger,
          width: 1,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _danger,
          width: 1.5,
        ),
      ),

      errorStyle: const TextStyle(
        color: _danger,
        fontSize: 12,
      ),

      labelStyle: TextStyle(
        color: textColor,
      ),
    );
  }

  // -------------------------------------------------------------
  // TITLE
  // -------------------------------------------------------------

  Widget _buildTitleField(
    Color cardBg,
    bool isDark,
  ) {
    return TextFormField(
      controller: _titleController,

      decoration: _fieldDecoration(
        hint: 'e.g. Lunch at Olive',
        fillColor: cardBg,
        isDark: isDark,
      ),

      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),

      cursorColor: _navy,

      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter an expense title';
        }

        return null;
      },
    );
  }

  // -------------------------------------------------------------
  // AMOUNT
  // -------------------------------------------------------------

  Widget _buildAmountField(
    Color cardBg,
    bool isDark,
  ) {
    final currencySymbol =
        AppState.instance.currencySymbol;

    final prefixColor =
        isDark ? Colors.white70 : Colors.black54;

    return TextFormField(
      controller: _amountController,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration: _fieldDecoration(
        hint: '0.00',
        fillColor: cardBg,
        isDark: isDark,

        prefix: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 8,
          ),
          child: Text(
            currencySymbol.trim(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: prefixColor,
            ),
          ),
        ),
      ),

      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),

      cursorColor: _navy,

      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter an amount';
        }

        final parsed =
            double.tryParse(val.trim());

        if (parsed == null || parsed <= 0) {
          return 'Please enter a valid amount greater than 0';
        }

        return null;
      },
    );
  }

  // -------------------------------------------------------------
  // CATEGORY
  // -------------------------------------------------------------

  Widget _buildCategoryDropdown(
    Color cardBg,
    bool isDark,
  ) {
    final textColor =
        isDark ? Colors.white : Colors.black87;

    final iconColor =
        isDark ? Colors.white54 : Colors.black45;

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,

      icon: Icon(
        Icons.keyboard_arrow_down,
        color: iconColor,
      ),

      dropdownColor:
          isDark
              ? const Color(0xFF1E2235)
              : Colors.white,

      decoration: _fieldDecoration(
        hint: 'Select category',
        fillColor: cardBg,
        isDark: isDark,
      ),

      hint: Text(
        'Select category',
        style: TextStyle(
          color:
              isDark
                  ? Colors.white38
                  : Colors.black26,
          fontSize: 15,
        ),
      ),

      style: TextStyle(
        color: textColor,
        fontSize: 15,
      ),

      items: AppCategory.categories.map((c) {
        return DropdownMenuItem<String>(
          value: c.name,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.iconBg,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Icon(
                  c.icon,
                  size: 16,
                  color: c.color,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                c.name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },

      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please select a category';
        }

        return null;
      },
    );
  }

  // -------------------------------------------------------------
  // DATE
  // -------------------------------------------------------------

  Widget _buildDateField(
    Color cardBg,
    bool isDark,
  ) {
    final iconColor =
        isDark ? Colors.white54 : Colors.black45;

    return InkWell(
      onTap: _pickDate,

      borderRadius: BorderRadius.circular(14),

      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(_formattedDate),

          initialValue: _formattedDate,

          decoration: _fieldDecoration(
            fillColor: cardBg,
            isDark: isDark,

            suffix: Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: iconColor,
              ),
            ),
          ),

          style: TextStyle(
            fontSize: 15,
            color:
                isDark
                    ? Colors.white
                    : Colors.black87,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // NOTE
  // -------------------------------------------------------------

  Widget _buildNoteField(
    Color cardBg,
    bool isDark,
  ) {
    return TextFormField(
      controller: _noteController,

      maxLines: 3,

      decoration: _fieldDecoration(
        hint: 'Add a note (optional)...',
        fillColor: cardBg,
        isDark: isDark,
      ),

      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),

      cursorColor: _navy,
    );
  }

  // -------------------------------------------------------------
  // SAVE BUTTON
  // -------------------------------------------------------------

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : _saveExpense,

        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          disabledBackgroundColor:
              _navy.withValues(alpha: 0.5),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          elevation: 0,
        ),

        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isEditing
                    ? 'Update Expense'
                    : 'Save Expense',

                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DELETE BUTTON
  // -------------------------------------------------------------

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed:
            _isLoading ? null : _confirmDelete,

        icon: const Icon(
          Icons.delete_outline,
          color: _danger,
          size: 18,
        ),

        label: const Text(
          'Delete Expense',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _danger,
          ),
        ),

        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: _danger,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}