import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
  static final _compact = NumberFormat.compact();
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _shortMonth = DateFormat('MMM');
  static final _dayMonth = DateFormat('d MMM');
  static final _fullDate = DateFormat('EEE, d MMM yyyy');

  static String currency(double amount) => _currency.format(amount);

  static String compact(double amount) => _compact.format(amount);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String shortMonth(DateTime date) => _shortMonth.format(date);

  static String dayMonth(DateTime date) => _dayMonth.format(date);

  static String fullDate(DateTime date) => _fullDate.format(date);

  static String dateRange(DateTimeRange range) {
    if (DateUtils.isSameDay(range.start, range.end)) return dayMonth(range.start);
    return '${dayMonth(range.start)} – ${dayMonth(range.end)}';
  }

  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(date);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return fullDate(date);
  }
}
