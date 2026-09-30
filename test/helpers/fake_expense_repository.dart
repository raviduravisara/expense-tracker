import 'dart:async';

import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/expense_category.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final StreamController<List<Expense>> controller = StreamController<List<Expense>>.broadcast();
  final List<Expense> saved = [];
  final List<String> deleted = [];
  final List<({DateTime from, DateTime to})> watchedRanges = [];
  Object? saveError;

  @override
  Stream<List<Expense>> watchExpenses({required DateTime from, required DateTime to}) {
    watchedRanges.add((from: from, to: to));
    return controller.stream;
  }

  @override
  Future<void> save(Expense expense) async {
    if (saveError != null) throw saveError!;
    saved.add(expense);
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

Expense buildExpense({
  String? id = 'id',
  String title = 'Lunch',
  double amount = 100,
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
  String? note,
}) {
  final day = date ?? DateTime(2026, 9, 15);
  return Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: day,
    createdAt: day,
    note: note,
  );
}
