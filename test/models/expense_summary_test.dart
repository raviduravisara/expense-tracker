import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

void main() {
  final expenses = [
    buildExpense(id: '1', amount: 300, date: DateTime(2026, 9, 20, 9)),
    buildExpense(
      id: '2',
      amount: 100,
      category: ExpenseCategory.transport,
      date: DateTime(2026, 9, 20, 18),
    ),
    buildExpense(id: '3', amount: 600, date: DateTime(2026, 9, 5)),
    buildExpense(id: '4', amount: 50, category: ExpenseCategory.bills, date: DateTime(2026, 7, 1)),
  ];

  test('total sums all amounts', () {
    expect(ExpenseSummary.total(expenses), 1050);
    expect(ExpenseSummary.total(const []), 0);
  });

  test('groupByDay groups by calendar day, newest first', () {
    final groups = ExpenseSummary.groupByDay(expenses);

    expect(groups.map((g) => g.day), [
      DateTime(2026, 9, 20),
      DateTime(2026, 9, 5),
      DateTime(2026, 7, 1),
    ]);
    expect(groups.first.expenses.length, 2);
    expect(groups.first.total, 400);
  });

  test('byCategory returns totals and shares sorted by amount', () {
    final totals = ExpenseSummary.byCategory(expenses);

    expect(totals.first.category, ExpenseCategory.food);
    expect(totals.first.amount, 900);
    expect(totals.first.share, closeTo(900 / 1050, 0.0001));
    expect(totals.map((t) => t.share).reduce((a, b) => a + b), closeTo(1, 0.0001));
  });

  test('byMonth returns a fixed window including empty months', () {
    final months = ExpenseSummary.byMonth(expenses, endMonth: DateTime(2026, 9), months: 3);

    expect(months.map((m) => m.month), [DateTime(2026, 7), DateTime(2026, 8), DateTime(2026, 9)]);
    expect(months.map((m) => m.amount), [50, 0, 1000]);
  });

  test('largest returns the biggest expense', () {
    expect(ExpenseSummary.largest(expenses)?.id, '3');
    expect(ExpenseSummary.largest(const []), isNull);
  });
}
