import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import '../../models/expense_category.dart';
import '../../models/expense_filter.dart';
import '../../models/expense_summary.dart';

class ExpensesController extends ChangeNotifier {
  ExpensesController(this._repository, {DateTime? now})
    : _now = now,
      _month = _monthOf(now ?? DateTime.now()) {
    _subscribe();
  }

  final ExpenseRepository _repository;
  final DateTime? _now;
  StreamSubscription<List<Expense>>? _subscription;

  DateTime _month;
  ExpenseFilter _filter = const ExpenseFilter();
  List<Expense> _expenses = const [];
  bool _isLoading = true;
  Object? _error;

  DateTime get month => _month;
  ExpenseFilter get filter => _filter;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  List<Expense> get monthExpenses => _expenses;
  List<Expense> get visibleExpenses => _expenses.where(_filter.matches).toList();
  double get monthTotal => ExpenseSummary.total(_expenses);
  DateTime get currentMonth => _monthOf(_now ?? DateTime.now());
  bool get canGoToNextMonth => _month.isBefore(currentMonth);

  static DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  void _subscribe() {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    _subscription = _repository
        .watchExpenses(from: _month, to: DateTime(_month.year, _month.month + 1))
        .listen(
          (expenses) {
            _expenses = expenses;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void retry() {
    _subscribe();
    notifyListeners();
  }

  void previousMonth() => showMonth(DateTime(_month.year, _month.month - 1));

  void nextMonth() {
    if (canGoToNextMonth) showMonth(DateTime(_month.year, _month.month + 1));
  }

  void showMonth(DateTime month) {
    final target = _monthOf(month);
    if (target == _month) return;
    _month = target;
    _expenses = const [];
    _filter = _filter.copyWith(clearDateRange: true);
    _subscribe();
    notifyListeners();
  }

  void setCategory(ExpenseCategory? category) {
    _filter = _filter.copyWith(category: category, clearCategory: category == null);
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _filter = _filter.copyWith(dateRange: range, clearDateRange: range == null);
    notifyListeners();
  }

  void setQuery(String query) {
    _filter = _filter.copyWith(query: query);
    notifyListeners();
  }

  void clearFilters() {
    _filter = const ExpenseFilter();
    notifyListeners();
  }

  Future<void> delete(Expense expense) async {
    final previous = _expenses;
    _expenses = _expenses.where((e) => e.id != expense.id).toList();
    notifyListeners();
    try {
      await _repository.delete(expense.id!);
    } catch (_) {
      _expenses = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restore(Expense expense) => _repository.save(expense);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
