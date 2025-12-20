import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;

    String dateText;
    if (isToday) {
      dateText = '今日';
    } else if (isYesterday) {
      dateText = '昨日';
    } else {
      dateText = DateFormat('MM/dd (E)', 'ja_JP').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
