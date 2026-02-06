import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_tokens.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name (e.g., Monday)
    } else {
      return DateFormat('MMM d, yyyy').format(date); // e.g., Feb 2, 2026
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceLg),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
              thickness: 0.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMd,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceMd,
                vertical: DesignTokens.spaceXs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Text(
                _formatDate(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
