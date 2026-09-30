import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense_category.dart';

class Expense {
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdAt,
    this.note,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    final date = (map['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Expense(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.fromName(map['category'] as String?),
      date: date,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? date,
      note: map['note'] as String?,
    );
  }

  final String? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final DateTime createdAt;
  final String? note;

  bool get isNew => id == null;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'category': category.name,
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(createdAt),
    'note': hasNote ? note!.trim() : null,
  };

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    DateTime? createdAt,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
