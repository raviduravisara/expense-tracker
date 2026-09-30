import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

void main() {
  group('ExpenseFilter', () {
    final lunch = buildExpense(title: 'Lunch', note: 'Pizza place', date: DateTime(2026, 9, 10));
    final bus = buildExpense(
      title: 'Bus ticket',
      category: ExpenseCategory.transport,
      date: DateTime(2026, 9, 20, 18, 30),
    );

    test('empty filter matches everything and is inactive', () {
      const filter = ExpenseFilter();
      expect(filter.isActive, isFalse);
      expect(filter.matches(lunch), isTrue);
      expect(filter.matches(bus), isTrue);
    });

    test('filters by category', () {
      const filter = ExpenseFilter(category: ExpenseCategory.transport);
      expect(filter.matches(lunch), isFalse);
      expect(filter.matches(bus), isTrue);
    });

    test('filters by inclusive date range', () {
      final filter = ExpenseFilter(
        dateRange: DateTimeRange(start: DateTime(2026, 9, 15), end: DateTime(2026, 9, 20)),
      );
      expect(filter.matches(lunch), isFalse);
      expect(filter.matches(bus), isTrue);
    });

    test('searches title and note case-insensitively', () {
      expect(const ExpenseFilter(query: 'PIZZA').matches(lunch), isTrue);
      expect(const ExpenseFilter(query: 'ticket').matches(bus), isTrue);
      expect(const ExpenseFilter(query: 'ticket').matches(lunch), isFalse);
    });

    test('copyWith can clear individual fields', () {
      final filter = ExpenseFilter(
        category: ExpenseCategory.food,
        dateRange: DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 2)),
      );
      final cleared = filter.copyWith(clearCategory: true);

      expect(cleared.category, isNull);
      expect(cleared.dateRange, filter.dateRange);
      expect(filter.copyWith(clearDateRange: true).dateRange, isNull);
    });
  });
}
