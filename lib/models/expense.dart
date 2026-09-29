import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import 'category_model.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final DateTime? createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.createdAt,
  });

  AppCategory get categoryInfo => AppCategory.fromName(category);

  String get formattedAmount =>
      '${AppState.instance.currencySymbol}${amount.abs().toStringAsFixed(2)}';

  String get formattedDate => DateFormat('MMM d, yyyy').format(date);

  factory Expense.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    DateTime parsedDate;
    final dateVal = data['date'];
    if (dateVal is Timestamp) {
      parsedDate = dateVal.toDate();
    } else if (dateVal is String) {
      parsedDate = DateTime.tryParse(dateVal) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    final createdVal = data['createdAt'];
    if (createdVal is Timestamp) {
      parsedCreatedAt = createdVal.toDate();
    }

    double parsedAmount = 0.0;
    final amountVal = data['amount'];
    if (amountVal is num) {
      parsedAmount = amountVal.toDouble();
    } else if (amountVal is String) {
      parsedAmount = double.tryParse(amountVal) ?? 0.0;
    }

    return Expense(
      id: document.id,
      title: data['title']?.toString() ?? '',
      amount: parsedAmount,
      category: data['category']?.toString() ?? 'Other',
      date: parsedDate,
      note: data['note']?.toString() ?? '',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}