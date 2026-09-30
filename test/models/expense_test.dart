import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

void main() {
  group('Expense', () {
    test('round-trips through a Firestore map', () {
      final expense = buildExpense(note: '  With friends  ');
      final restored = Expense.fromMap('abc', expense.toMap());

      expect(restored.id, 'abc');
      expect(restored.title, expense.title);
      expect(restored.amount, expense.amount);
      expect(restored.category, expense.category);
      expect(restored.date, expense.date);
      expect(restored.note, 'With friends');
    });

    test('stores blank notes as null', () {
      expect(buildExpense(note: '   ').toMap()['note'], isNull);
    });

    test('falls back to "other" for unknown categories', () {
      final expense = Expense.fromMap('x', {
        'title': 'Mystery',
        'amount': 5,
        'category': 'unknown',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      expect(expense.category, ExpenseCategory.other);
      expect(expense.amount, 5.0);
      expect(expense.createdAt, DateTime(2026, 1, 1));
    });

    test('isNew is true only without an id', () {
      expect(buildExpense(id: null).isNew, isTrue);
      expect(buildExpense().isNew, isFalse);
    });
  });
}
