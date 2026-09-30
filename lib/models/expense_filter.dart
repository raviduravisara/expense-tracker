import 'package:flutter/material.dart';

import 'expense.dart';
import 'expense_category.dart';

class ExpenseFilter {
  const ExpenseFilter({this.category, this.dateRange, this.query = ''});

  final ExpenseCategory? category;
  final DateTimeRange? dateRange;
  final String query;

  bool get isActive => category != null || dateRange != null || query.trim().isNotEmpty;

  bool matches(Expense expense) {
    if (category != null && expense.category != category) return false;

    if (dateRange != null) {
      final day = DateUtils.dateOnly(expense.date);
      final start = DateUtils.dateOnly(dateRange!.start);
      final end = DateUtils.dateOnly(dateRange!.end);
      if (day.isBefore(start) || day.isAfter(end)) return false;
    }

    final term = query.trim().toLowerCase();
    if (term.isNotEmpty) {
      final inTitle = expense.title.toLowerCase().contains(term);
      final inNote = expense.note?.toLowerCase().contains(term) ?? false;
      if (!inTitle && !inNote) return false;
    }

    return true;
  }

  ExpenseFilter copyWith({
    ExpenseCategory? category,
    DateTimeRange? dateRange,
    String? query,
    bool clearCategory = false,
    bool clearDateRange = false,
  }) {
    return ExpenseFilter(
      category: clearCategory ? null : category ?? this.category,
      dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
      query: query ?? this.query,
    );
  }
}
