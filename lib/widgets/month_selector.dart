import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    this.onNext,
    this.color,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color);

    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: onPrevious,
          color: color,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(Formatters.monthYear(month), style: style),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: onNext,
          color: color,
          disabledColor: color?.withValues(alpha: 0.3),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
