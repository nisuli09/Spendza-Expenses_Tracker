import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  bool _isDarkMode = false;
  String _currencySymbol = 'Rs. ';
  String _currencyCode = 'LKR';
  String _userName = 'Alex Morgan';
  String _userEmail = 'alex@example.com';

  bool _isLoggedIn = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLoggedIn => _isLoggedIn;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  String get userName => _userName;
  String get userEmail => _userEmail;

  void toggleDarkMode(bool val) {
    _isDarkMode = val;
    notifyListeners();
  }

  void setCurrency(String code, String symbol) {
    _currencyCode = code;
    _currencySymbol = symbol;
    notifyListeners();
  }

  void updateUser(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  void login({required String name, required String email}) {
    _userName = name.isNotEmpty ? name : 'Alex Morgan';
    _userEmail = email.isNotEmpty ? email : 'alex@example.com';
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  String formatAmount(double amount) {
    return '$_currencySymbol${amount.abs().toStringAsFixed(2)}';
  }
}
