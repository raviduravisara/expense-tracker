import 'package:expense_tracker/features/expenses/screens/expense_form_screen.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;

  setUp(() => repository = FakeExpenseRepository());

  Future<void> pumpForm(WidgetTester tester, {bool editing = false}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExpenseFormScreen(
                    repository: repository,
                    expense: editing ? buildExpense(title: 'Old title', amount: 75.5) : null,
                    today: DateTime(2026, 9, 30),
                  ),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  testWidgets('shows validation errors when submitting an empty form', (tester) async {
    await pumpForm(tester);

    await tapButton(tester, 'Add expense');
    await tester.pump();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please enter an amount'), findsOneWidget);
    expect(find.text('Please select a category'), findsOneWidget);
    expect(repository.saved, isEmpty);
  });

  testWidgets('saves a valid expense', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Groceries');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '1250.50');
    await tester.tap(find.text(ExpenseCategory.shopping.label));
    await tapButton(tester, 'Add expense');
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.isNew, isTrue);
    expect(saved.title, 'Groceries');
    expect(saved.amount, 1250.5);
    expect(saved.category, ExpenseCategory.shopping);
    expect(saved.date, DateTime(2026, 9, 30));
    expect(saved.note, isNull);
  });

  testWidgets('prefills and updates an existing expense', (tester) async {
    await pumpForm(tester, editing: true);

    expect(find.text('Edit expense'), findsOneWidget);
    expect(find.text('Old title'), findsOneWidget);
    expect(find.text('75.50'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'New title');
    await tapButton(tester, 'Save changes');
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.id, 'id');
    expect(saved.title, 'New title');
    expect(saved.category, ExpenseCategory.food);
  });

  testWidgets('shows an error message when saving fails', (tester) async {
    repository.saveError = Exception('offline');
    await pumpForm(tester, editing: true);

    await tapButton(tester, 'Save changes');
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });
}
