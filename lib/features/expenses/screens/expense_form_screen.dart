import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/sync.dart';
import '../../../core/utils/validators.dart';
import '../../../data/expense_repository.dart';
import '../../../models/expense.dart';
import '../../../models/expense_category.dart';
import '../../../widgets/confirm_dialog.dart';

enum ExpenseFormAction { added, updated, deleted }

class ExpenseFormResult {
  const ExpenseFormResult(this.action, this.expense, {this.synced = true});

  final ExpenseFormAction action;
  final Expense expense;
  final bool synced;
}

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.repository, this.expense, this.today});

  final ExpenseRepository repository;
  final Expense? expense;
  final DateTime? today;

  static Future<ExpenseFormResult?> open(BuildContext context, {Expense? expense}) {
    final repository = context.read<ExpenseRepository>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(repository: repository, expense: expense),
      ),
    );
  }

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;
  late final DateTime _today;
  late DateTime _date;
  ExpenseCategory? _category;
  bool _submitted = false;
  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
    _date = expense?.date ?? _today;
    _category = expense?.category;
    _titleController = TextEditingController(text: expense?.title);
    _amountController = TextEditingController(
      text: expense == null ? null : _formatAmount(expense.amount),
    );
    _noteController = TextEditingController(text: expense?.note);
    _dateController = TextEditingController(text: Formatters.fullDate(_date));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  static String _formatAmount(double amount) {
    return amount == amount.truncateToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  bool get _hasChanges {
    final expense = widget.expense;
    final title = _titleController.text.trim();
    final amount = _amountController.text.trim();
    final note = _noteController.text.trim();

    if (expense == null) {
      return title.isNotEmpty ||
          amount.isNotEmpty ||
          note.isNotEmpty ||
          _category != null ||
          !DateUtils.isSameDay(_date, _today);
    }
    return title != expense.title ||
        double.tryParse(amount) != expense.amount ||
        _category != expense.category ||
        !DateUtils.isSameDay(_date, expense.date) ||
        note != (expense.note ?? '');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(_today) ? _today : _date,
      firstDate: DateTime(2000),
      lastDate: _today,
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateController.text = Formatters.fullDate(picked);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final note = _noteController.text.trim();
    final expense = Expense(
      id: widget.expense?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _category!,
      date: DateUtils.dateOnly(_date),
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      note: note.isEmpty ? null : note,
    );

    setState(() => _saving = true);
    try {
      final synced = await confirmSynced(widget.repository.save(expense));
      if (!mounted) return;
      final action = _isEditing ? ExpenseFormAction.updated : ExpenseFormAction.added;
      Navigator.of(context).pop(ExpenseFormResult(action, expense, synced: synced));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete expense?',
      message: '"${widget.expense!.title}" will be removed from your history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pop(ExpenseFormResult(ExpenseFormAction.deleted, widget.expense!));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: 'Your unsaved changes will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_saving && !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Delete',
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: Validators.titleMaxLength,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Lunch with friends',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                      validator: Validators.title,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.payments_outlined),
                        prefixText: 'Rs. ',
                      ),
                      validator: Validators.amount,
                    ),
                    const SizedBox(height: 24),
                    Text('Category', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _CategoryField(
                      initialValue: _category,
                      enabled: !_saving,
                      onChanged: (category) => setState(() => _category = category),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _dateController,
                      enabled: !_saving,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: Validators.noteMaxLength,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      validator: Validators.note,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Text(_isEditing ? 'Save changes' : 'Add expense'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  final ExpenseCategory? initialValue;
  final bool enabled;
  final ValueChanged<ExpenseCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FormField<ExpenseCategory>(
      initialValue: initialValue,
      validator: (value) => value == null ? 'Please select a category' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ExpenseCategory.values)
                ChoiceChip(
                  avatar: Icon(category.icon, size: 18, color: category.color),
                  label: Text(category.label),
                  selected: field.value == category,
                  selectedColor: category.color.withValues(alpha: 0.2),
                  side: field.value == category ? BorderSide(color: category.color) : null,
                  onSelected: enabled
                      ? (_) {
                          field.didChange(category);
                          onChanged(category);
                        }
                      : null,
                ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(field.errorText!, style: TextStyle(color: scheme.error, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
