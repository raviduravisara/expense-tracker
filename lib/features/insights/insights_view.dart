import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import '../../models/expense_category.dart';
import '../../models/expense_summary.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/state_views.dart';
import '../expenses/expenses_controller.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({super.key, required this.onCategorySelected});

  final ValueChanged<ExpenseCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpensesController>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: MonthSelector(
                  month: controller.month,
                  onPrevious: controller.previousMonth,
                  onNext: controller.canGoToNextMonth ? controller.nextMonth : null,
                ),
              ),
            ),
            Expanded(
              child: _InsightsContent(
                key: ValueKey(controller.month),
                month: controller.month,
                isCurrentMonth: controller.month == controller.currentMonth,
                repository: context.read<ExpenseRepository>(),
                onCategorySelected: onCategorySelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsContent extends StatefulWidget {
  const _InsightsContent({
    super.key,
    required this.month,
    required this.isCurrentMonth,
    required this.repository,
    required this.onCategorySelected,
  });

  static const trendMonths = 6;

  final DateTime month;
  final bool isCurrentMonth;
  final ExpenseRepository repository;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  @override
  State<_InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends State<_InsightsContent> {
  late Stream<List<Expense>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _watch();
  }

  Stream<List<Expense>> _watch() {
    final month = widget.month;
    return widget.repository.watchExpenses(
      from: DateTime(month.year, month.month - (_InsightsContent.trendMonths - 1)),
      to: DateTime(month.year, month.month + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MessageView(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t load insights',
            message: describeError(snapshot.error!),
            actionLabel: 'Try again',
            onAction: () => setState(() => _stream = _watch()),
            isError: true,
          );
        }
        if (!snapshot.hasData) return const LoadingView(message: 'Crunching numbers...');

        final month = widget.month;
        final all = snapshot.data!;
        final monthExpenses = all
            .where((e) => e.date.year == month.year && e.date.month == month.month)
            .toList();
        final trend = ExpenseSummary.byMonth(
          all,
          endMonth: month,
          months: _InsightsContent.trendMonths,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final breakdown = monthExpenses.isEmpty
                ? const _EmptyMonthCard()
                : _CategoryBreakdownCard(
                    totals: ExpenseSummary.byCategory(monthExpenses),
                    onCategorySelected: widget.onCategorySelected,
                  );
            final trendCard = _TrendCard(trend: trend);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                _StatsRow(
                  expenses: monthExpenses,
                  month: month,
                  isCurrentMonth: widget.isCurrentMonth,
                ),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: breakdown),
                      const SizedBox(width: 16),
                      Expanded(child: trendCard),
                    ],
                  )
                else ...[
                  breakdown,
                  const SizedBox(height: 16),
                  trendCard,
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.expenses, required this.month, required this.isCurrentMonth});

  final List<Expense> expenses;
  final DateTime month;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final total = ExpenseSummary.total(expenses);
    final days = isCurrentMonth
        ? DateTime.now().day
        : DateUtils.getDaysInMonth(month.year, month.month);
    final largest = ExpenseSummary.largest(expenses);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Total',
            value: Formatters.currency(total),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.today_rounded,
            label: 'Daily avg',
            value: Formatters.currency(total / days),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            label: 'Largest',
            value: largest == null ? '—' : Formatters.currency(largest.amount),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyMonthCard extends StatelessWidget {
  const _EmptyMonthCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Spending by category',
      child: MessageView(
        icon: Icons.pie_chart_outline_rounded,
        title: 'Nothing to show yet',
        message: 'Add expenses for this month to see your category breakdown.',
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.totals, required this.onCategorySelected});

  final List<CategoryTotal> totals;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grandTotal = totals.fold<double>(0, (sum, t) => sum + t.amount);

    return _SectionCard(
      title: 'Spending by category',
      subtitle: 'Tap a category to see its expenses',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 64,
                    sections: [
                      for (final total in totals)
                        PieChartSectionData(
                          value: total.amount,
                          color: total.category.color,
                          radius: 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: theme.textTheme.labelMedium),
                    Text(
                      Formatters.compact(grandTotal),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final total in totals)
            _CategoryRow(total: total, onTap: () => onCategorySelected(total.category)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.total, required this.onTap});

  final CategoryTotal total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = total.category.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            CategoryAvatar(category: total.category, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${total.category.label} · ${(total.share * 100).round()}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        Formatters.currency(total.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total.share,
                      minHeight: 6,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final List<MonthTotal> trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highest = trend.fold<double>(0, (max, t) => t.amount > max ? t.amount : max);
    final average = trend.fold<double>(0, (sum, t) => sum + t.amount) / trend.length;
    const noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return _SectionCard(
      title: 'Last ${trend.length} months',
      subtitle: 'Average ${Formatters.currency(average)} per month',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: highest == 0 ? 1 : highest * 1.15,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: noTitles,
              rightTitles: noTitles,
              topTitles: noTitles,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Formatters.shortMonth(trend[value.toInt()].month),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  Formatters.currency(rod.toY),
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < trend.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: trend[i].amount,
                      width: 22,
                      color: i == trend.length - 1
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
