import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() => _instance;

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the currently logged-in user's expenses collection
  CollectionReference<Map<String, dynamic>> get _expenses {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses');
  }

  // Add expense
  Future<String> addExpense(Expense expense) async {
    final docRef = await _expenses.add(expense.toFirestore());
    return docRef.id;
  }

  // Get expenses belonging only to the currently logged-in user
  Stream<List<Expense>> getExpenses() {
    return _expenses
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromFirestore(doc))
              .toList(),
        );
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    if (expense.id.isEmpty) {
      throw Exception('Expense ID cannot be empty.');
    }

    await _expenses.doc(expense.id).update(expense.toFirestore());
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    if (expenseId.isEmpty) {
      throw Exception('Expense ID cannot be empty.');
    }

    await _expenses.doc(expenseId).delete();
  }

  // Clear all expenses for the currently logged-in user
  Future<void> clearAllExpenses() async {
    final snapshot = await _expenses.get();

    // Firestore allows a maximum of 500 operations per batch.
    // This handles larger collections safely.
    const batchLimit = 500;

    for (var i = 0; i < snapshot.docs.length; i += batchLimit) {
      final batch = _firestore.batch();

      final end = (i + batchLimit < snapshot.docs.length)
          ? i + batchLimit
          : snapshot.docs.length;

      for (var j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].reference);
      }

      await batch.commit();
    }
  }

  // Check whether the current user has any expenses
  Future<bool> hasExpenses() async {
    final snapshot = await _expenses.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}