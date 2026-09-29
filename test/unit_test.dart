import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendza/models/category_model.dart';
import 'package:spendza/models/expense.dart';
import 'package:spendza/services/app_state.dart';

void main() {
  group('AppCategory tests', () {
    test('Correctly identifies known categories', () {
      final foodCat = AppCategory.fromName('Food');
      expect(foodCat.name, 'Food');
      expect(foodCat.icon, Icons.restaurant);

      final billsCat = AppCategory.fromName('Bills');
      expect(billsCat.name, 'Bills');
      expect(billsCat.icon, Icons.receipt_long);
    });

    test('Falls back to Other for null or unknown category', () {
      final nullCat = AppCategory.fromName(null);
      expect(nullCat.name, 'Other');

      final unknownCat = AppCategory.fromName('Space Exploration');
      expect(unknownCat.name, 'Other');
    });

    test('Contains standard categories', () {
      final names = AppCategory.names;
      expect(names, contains('Food'));
      expect(names, contains('Transport'));
      expect(names, contains('Shopping'));
      expect(names, contains('Bills'));
      expect(names, contains('Entertainment'));
      expect(names, contains('Health'));
      expect(names, contains('Other'));
    });
  });

  group('Expense model tests', () {
    test('Creates Expense and verifies getters', () {
      final expense = Expense(
        id: 'exp123',
        title: 'Lunch at Olive',
        amount: 15.50,
        category: 'Food',
        date: DateTime(2026, 9, 28),
        note: 'Team lunch',
      );

      expect(expense.id, 'exp123');
      expect(expense.title, 'Lunch at Olive');
      expect(expense.amount, 15.50);
      expect(expense.formattedAmount, 'Rs. 15.50');
      expect(expense.categoryInfo.name, 'Food');
      expect(expense.categoryInfo.icon, Icons.restaurant);
      expect(expense.note, 'Team lunch');
    });

    test('toFirestore serializes fields correctly', () {
      final date = DateTime(2026, 9, 28);
      final expense = Expense(
        id: 'exp456',
        title: 'Uber',
        amount: 8.50,
        category: 'Transport',
        date: date,
        note: 'Office commute',
      );

      final map = expense.toFirestore();
      expect(map['title'], 'Uber');
      expect(map['amount'], 8.50);
      expect(map['category'], 'Transport');
      expect(map['note'], 'Office commute');
    });

    test('copyWith creates modified clone', () {
      final original = Expense(
        id: '1',
        title: 'Coffee',
        amount: 4.50,
        category: 'Food',
        date: DateTime(2026, 9, 28),
        note: '',
      );

      final updated = original.copyWith(amount: 5.00, title: 'Latte');
      expect(updated.id, '1');
      expect(updated.title, 'Latte');
      expect(updated.amount, 5.00);
      expect(updated.category, 'Food');
    });
  });

  group('AppState tests', () {
    test('Currency defaults to LKR and updates correctly', () {
      final appState = AppState.instance;
      expect(appState.currencyCode, 'LKR');
      expect(appState.currencySymbol, 'Rs. ');
      expect(appState.formatAmount(25.0), 'Rs. 25.00');

      appState.setCurrency('EUR', '€');
      expect(appState.currencyCode, 'EUR');
      expect(appState.currencySymbol, '€');
      expect(appState.formatAmount(25.0), '€25.00');

      // Reset to LKR
      appState.setCurrency('LKR', 'Rs. ');
      expect(appState.currencyCode, 'LKR');
      expect(appState.currencySymbol, 'Rs. ');
    });

    test('User profile and dark mode update', () {
      final appState = AppState.instance;
      appState.updateUser('John Doe', 'john@example.com');
      expect(appState.userName, 'John Doe');
      expect(appState.userEmail, 'john@example.com');

      appState.toggleDarkMode(true);
      expect(appState.isDarkMode, isTrue);

      appState.toggleDarkMode(false);
      expect(appState.isDarkMode, isFalse);

      // Restore
      appState.updateUser('Alex Morgan', 'alex@example.com');
    });

    test('Login and logout update auth state and user information', () {
      final appState = AppState.instance;

      appState.logout();
      expect(appState.isLoggedIn, isFalse);

      appState.login(name: 'Sarah Connor', email: 'sarah@example.com');
      expect(appState.isLoggedIn, isTrue);
      expect(appState.userName, 'Sarah Connor');
      expect(appState.userEmail, 'sarah@example.com');

      appState.logout();
      expect(appState.isLoggedIn, isFalse);

      // Restore
      appState.login(name: 'Alex Morgan', email: 'alex@example.com');
    });
  });
}
