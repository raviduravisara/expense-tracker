import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food & Dining', Icons.restaurant_rounded, Color(0xFFF57C00)),
  transport('Transport', Icons.directions_bus_rounded, Color(0xFF1E88E5)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFF8E24AA)),
  bills('Bills & Utilities', Icons.receipt_long_rounded, Color(0xFF00897B)),
  entertainment('Entertainment', Icons.movie_rounded, Color(0xFFD81B60)),
  health('Health', Icons.favorite_rounded, Color(0xFFE53935)),
  education('Education', Icons.school_rounded, Color(0xFF3949AB)),
  other('Other', Icons.category_rounded, Color(0xFF6D7B8A));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static ExpenseCategory fromName(String? name) =>
      values.firstWhere((category) => category.name == name, orElse: () => other);
}
