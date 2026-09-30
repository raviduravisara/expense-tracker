import 'package:flutter/material.dart';

import 'expense.dart';
import 'expense_category.dart';

class DayGroup {
  const DayGroup(this.day, this.expenses);

  final DateTime day;
  final List<Expense> expenses;

  double get total => ExpenseSummary.total(expenses);
}

class CategoryTotal {
  const CategoryTotal(this.category, this.amount, this.share);

  final ExpenseCategory category;
  final double amount;
  final double share;
}

class MonthTotal {
  const MonthTotal(this.month, this.amount);

  final DateTime month;
  final double amount;
}

abstract final class ExpenseSummary {
  static double total(Iterable<Expense> expenses) =>
      expenses.fold(0, (sum, expense) => sum + expense.amount);

  static List<DayGroup> groupByDay(List<Expense> expenses) {
    final groups = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      groups.putIfAbsent(DateUtils.dateOnly(expense.date), () => []).add(expense);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final day in days) DayGroup(day, groups[day]!)];
  }

  static List<CategoryTotal> byCategory(List<Expense> expenses) {
    final sum = total(expenses);
    if (sum == 0) return const [];

    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals.entries
        .map((entry) => CategoryTotal(entry.key, entry.value, entry.value / sum))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static List<MonthTotal> byMonth(
    List<Expense> expenses, {
    required DateTime endMonth,
    int months = 6,
  }) {
    return List.generate(months, (index) {
      final month = DateTime(endMonth.year, endMonth.month - (months - 1 - index));
      final amount = total(
        expenses.where((e) => e.date.year == month.year && e.date.month == month.month),
      );
      return MonthTotal(month, amount);
    });
  }

  static Expense? largest(List<Expense> expenses) {
    if (expenses.isEmpty) return null;
    return expenses.reduce((a, b) => b.amount > a.amount ? b : a);
  }
}
