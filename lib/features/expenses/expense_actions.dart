import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import 'expenses_controller.dart';
import 'screens/expense_form_screen.dart';

Future<void> openExpenseForm(BuildContext context, {Expense? expense}) async {
  final controller = context.read<ExpensesController>();
  final messenger = ScaffoldMessenger.of(context);
  final result = await ExpenseFormScreen.open(context, expense: expense);
  if (result == null) return;

  if (result.action == ExpenseFormAction.deleted) {
    await deleteExpense(controller, messenger, result.expense);
    return;
  }

  final saved = result.expense;
  final inOtherMonth =
      saved.date.year != controller.month.year || saved.date.month != controller.month.month;
  final verb = result.action == ExpenseFormAction.added ? 'added' : 'updated';
  final message = !result.synced
      ? 'Expense saved offline. It will sync when you\'re back online.'
      : inOtherMonth
      ? 'Expense $verb to ${Formatters.monthYear(saved.date)}'
      : 'Expense $verb';

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        persist: false,
        action: inOtherMonth
            ? SnackBarAction(label: 'View', onPressed: () => controller.showMonth(saved.date))
            : null,
      ),
    );
}

Future<void> deleteExpense(
  ExpensesController controller,
  ScaffoldMessengerState messenger,
  Expense expense,
) async {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('"${expense.title}" deleted'),
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _runReportingErrors(messenger, controller.restore(expense)),
        ),
      ),
    );
  await _runReportingErrors(messenger, controller.delete(expense));
}

Future<void> _runReportingErrors(ScaffoldMessengerState messenger, Future<void> task) async {
  try {
    await task;
  } catch (error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(describeError(error))));
  }
}
