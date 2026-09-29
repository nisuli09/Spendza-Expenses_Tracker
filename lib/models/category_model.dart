import 'package:flutter/material.dart';

class AppCategory {
  final String name;
  final IconData icon;
  final Color color;
  final Color iconBg;

  const AppCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.iconBg,
  });

  static const List<AppCategory> categories = [
    AppCategory(
      name: 'Food',
      icon: Icons.restaurant,
      color: Color(0xFFFF9F43),
      iconBg: Color(0xFFFFF1DE),
    ),
    AppCategory(
      name: 'Transport',
      icon: Icons.directions_car_filled,
      color: Color(0xFF4E7DF0),
      iconBg: Color(0xFFE7EEFF),
    ),
    AppCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFFB07CF2),
      iconBg: Color(0xFFF3E8FF),
    ),
    AppCategory(
      name: 'Bills',
      icon: Icons.receipt_long,
      color: Color(0xFF17A883),
      iconBg: Color(0xFFE1FBF2),
    ),
    AppCategory(
      name: 'Entertainment',
      icon: Icons.local_movies,
      color: Color(0xFFE0555D),
      iconBg: Color(0xFFFFE8EC),
    ),
    AppCategory(
      name: 'Health',
      icon: Icons.local_pharmacy,
      color: Color(0xFF2FA88A),
      iconBg: Color(0xFFE3F8FA),
    ),
    AppCategory(
      name: 'Other',
      icon: Icons.category_outlined,
      color: Color(0xFF9AA0A6),
      iconBg: Color(0xFFF0F0F5),
    ),
  ];

  static AppCategory fromName(String? name) {
    if (name == null || name.isEmpty) {
      return categories.last;
    }
    return categories.firstWhere(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => categories.last,
    );
  }

  static List<String> get names => categories.map((c) => c.name).toList();
}
