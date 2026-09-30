import 'package:expense_tracker/core/utils/formatters.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/features/expenses/expenses_controller.dart';
import 'package:expense_tracker/features/expenses/screens/expenses_view.dart';
import 'package:expense_tracker/features/insights/insights_view.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;
  late ExpensesController controller;

  final expenses = [
    buildExpense(id: '1', title: 'Lunch', amount: 1200, date: DateTime(2026, 9, 28)),
    buildExpense(
      id: '2',
      title: 'Bus ticket',
      amount: 300,
      category: ExpenseCategory.transport,
      date: DateTime(2026, 9, 12),
      note: 'To campus',
    ),
  ];

  setUp(() {
    repository = FakeExpenseRepository();
    controller = ExpensesController(repository, now: DateTime(2026, 9, 30));
  });

  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ExpenseRepository>.value(value: repository),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  testWidgets('expenses view shows loading, then data, then filtered empty state', (tester) async {
    await pump(tester, const ExpensesView());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.controller.add(expenses);
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Bus ticket'), findsOneWidget);
    expect(find.text(Formatters.currency(1500)), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nothing matches');
    await tester.pumpAndSettle();
    expect(find.text('No matching expenses'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('expenses view shows empty and error states', (tester) async {
    await pump(tester, const ExpensesView());

    repository.controller.add(const []);
    await tester.pumpAndSettle();
    expect(find.text('No expenses yet'), findsOneWidget);

    repository.controller.addError(Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn\'t load expenses'), findsOneWidget);
  });

  testWidgets('insights view renders charts and breakdown', (tester) async {
    ExpenseCategory? selected;
    await pump(tester, InsightsView(onCategorySelected: (c) => selected = c));

    repository.controller.add(expenses);
    await tester.pumpAndSettle();

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.textContaining('Food & Dining'), findsOneWidget);

    await tester.tap(find.textContaining('Transport'));
    expect(selected, ExpenseCategory.transport);

    await tester.scrollUntilVisible(find.text('Last 6 months'), 200);
    expect(find.text('Last 6 months'), findsOneWidget);
  });
}
