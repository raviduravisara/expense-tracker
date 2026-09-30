import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/expense_category.dart';
import '../../../models/expense_summary.dart';
import '../../../widgets/month_selector.dart';
import '../../../widgets/state_views.dart';
import '../expense_actions.dart';
import '../expenses_controller.dart';
import '../widgets/expense_tile.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ExpensesController>().filter.query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<ExpensesController>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpensesController>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(child: _SummaryCard(controller: controller)),
            ),
            SliverToBoxAdapter(
              child: _FilterBar(
                controller: controller,
                searchController: _searchController,
                onClear: _clearFilters,
              ),
            ),
            ..._buildContent(controller),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(ExpensesController controller) {
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.only(bottom: 88), child: child),
    );

    if (controller.isLoading) {
      return [fill(const LoadingView(message: 'Loading expenses...'))];
    }

    if (controller.error != null) {
      return [
        fill(
          MessageView(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t load expenses',
            message: describeError(controller.error!),
            actionLabel: 'Try again',
            onAction: controller.retry,
            isError: true,
          ),
        ),
      ];
    }

    if (controller.monthExpenses.isEmpty) {
      return [
        fill(
          MessageView(
            icon: Icons.receipt_long_rounded,
            title: 'No expenses yet',
            message:
                'Nothing recorded for ${Formatters.monthYear(controller.month)}. '
                'Tap "Add expense" to get started.',
          ),
        ),
      ];
    }

    final visible = controller.visibleExpenses;
    if (visible.isEmpty) {
      return [
        fill(
          MessageView(
            icon: Icons.search_off_rounded,
            title: 'No matching expenses',
            message: 'Try a different search term or clear the filters.',
            actionLabel: 'Clear filters',
            onAction: _clearFilters,
          ),
        ),
      ];
    }

    final groups = ExpenseSummary.groupByDay(visible);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        sliver: SliverList.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) => _DaySection(group: groups[index]),
        ),
      ),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final ExpensesController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onCard = scheme.onPrimary;
    final count = controller.monthExpenses.length;
    final filter = controller.filter;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, Color.lerp(scheme.primary, scheme.tertiary, 0.6)!],
        ),
      ),
      child: Column(
        children: [
          MonthSelector(
            month: controller.month,
            color: onCard,
            onPrevious: controller.previousMonth,
            onNext: controller.canGoToNextMonth ? controller.nextMonth : null,
          ),
          const SizedBox(height: 4),
          Text(
            'Total spent',
            style: theme.textTheme.bodyMedium?.copyWith(color: onCard.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                controller.isLoading ? '—' : Formatters.currency(controller.monthTotal),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count == 1 ? '1 expense' : '$count expenses',
            style: theme.textTheme.bodySmall?.copyWith(color: onCard.withValues(alpha: 0.8)),
          ),
          if (filter.isActive && !controller.isLoading) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: onCard.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Filtered: ${Formatters.currency(ExpenseSummary.total(controller.visibleExpenses))}'
                ' · ${controller.visibleExpenses.length} of $count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.controller,
    required this.searchController,
    required this.onClear,
  });

  final ExpensesController controller;
  final TextEditingController searchController;
  final VoidCallback onClear;

  Future<void> _pickDateRange(BuildContext context) async {
    final month = controller.month;
    final today = DateUtils.dateOnly(DateTime.now());
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final range = await showDateRangePicker(
      context: context,
      firstDate: month,
      lastDate: monthEnd.isAfter(today) ? today : monthEnd,
      initialDateRange: controller.filter.dateRange,
      helpText: 'Filter by date',
    );
    if (range != null) controller.setDateRange(range);
  }

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    final dateRange = filter.dateRange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: searchController,
            builder: (context, value, _) => TextField(
              controller: searchController,
              onChanged: controller.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title or note',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          searchController.clear();
                          controller.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (filter.isActive) ...[
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Clear'),
                    onPressed: onClear,
                  ),
                  const SizedBox(width: 8),
                ],
                InputChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(dateRange == null ? 'Any date' : Formatters.dateRange(dateRange)),
                  selected: dateRange != null,
                  onPressed: () => _pickDateRange(context),
                  onDeleted: dateRange == null ? null : () => controller.setDateRange(null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All'),
                  selected: filter.category == null,
                  onSelected: (_) => controller.setCategory(null),
                ),
                for (final category in ExpenseCategory.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(category.icon, size: 18, color: category.color),
                    label: Text(category.label),
                    selected: filter.category == category,
                    onSelected: (selected) => controller.setCategory(selected ? category : null),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.group});

  final DayGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final controller = context.read<ExpensesController>();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(child: Text(Formatters.relativeDay(group.day), style: labelStyle)),
                Text(Formatters.currency(group.total), style: labelStyle),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  for (final expense in group.expenses)
                    ExpenseTile(
                      expense: expense,
                      onTap: () => openExpenseForm(context, expense: expense),
                      onDelete: () =>
                          deleteExpense(controller, ScaffoldMessenger.of(context), expense),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
