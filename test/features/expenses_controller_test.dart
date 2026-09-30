import 'package:expense_tracker/features/expenses/expenses_controller.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;
  late ExpensesController controller;

  setUp(() {
    repository = FakeExpenseRepository();
    controller = ExpensesController(repository, now: DateTime(2026, 9, 30));
  });

  tearDown(() => controller.dispose());

  test('starts loading and watches the current month', () {
    expect(controller.isLoading, isTrue);
    expect(repository.watchedRanges.single.from, DateTime(2026, 9));
    expect(repository.watchedRanges.single.to, DateTime(2026, 10));
  });

  test('exposes data, totals and filtered results', () async {
    repository.controller.add([
      buildExpense(id: '1', amount: 200),
      buildExpense(id: '2', amount: 50, category: ExpenseCategory.transport),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading, isFalse);
    expect(controller.monthTotal, 250);

    controller.setCategory(ExpenseCategory.transport);
    expect(controller.visibleExpenses.map((e) => e.id), ['2']);
    expect(controller.filter.isActive, isTrue);

    controller.clearFilters();
    expect(controller.visibleExpenses.length, 2);
  });

  test('surfaces stream errors', () async {
    repository.controller.addError(Exception('boom'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNotNull);
  });

  test('cannot navigate past the current month', () {
    expect(controller.canGoToNextMonth, isFalse);
    controller.nextMonth();
    expect(controller.month, DateTime(2026, 9));

    controller.previousMonth();
    expect(controller.month, DateTime(2026, 8));
    expect(controller.canGoToNextMonth, isTrue);
    expect(repository.watchedRanges.last.from, DateTime(2026, 8));
  });

  test('changing month clears the date range filter', () {
    controller.setDateRange(DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 5)));
    controller.setCategory(ExpenseCategory.food);
    controller.previousMonth();

    expect(controller.filter.dateRange, isNull);
    expect(controller.filter.category, ExpenseCategory.food);
  });

  test('delete removes the expense optimistically', () async {
    repository.controller.add([buildExpense(id: '1'), buildExpense(id: '2')]);
    await Future<void>.delayed(Duration.zero);

    await controller.delete(controller.monthExpenses.first);

    expect(controller.monthExpenses.map((e) => e.id), ['2']);
    expect(repository.deleted, ['1']);
  });
}
