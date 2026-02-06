import 'package:flutter/material.dart';

/// Message delivery status indicator
/// - Single tick: Message sent
/// - Double tick (gray): Message delivered
/// - Double tick (purple): Message read
class MessageStatusIndicator extends StatelessWidget {
  final String status; // 'sent', 'delivered', 'read'
  final Color? color;

  const MessageStatusIndicator({super.key, required this.status, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getColor() {
      if (color != null) return color!;

      switch (status) {
        case 'read':
          return const Color(0xFF6A0DAD); // Deep Purple
        case 'delivered':
          return isDark ? Colors.grey[400]! : Colors.grey[600]!;
        case 'sent':
        default:
          return isDark ? Colors.grey[500]! : Colors.grey[700]!;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'sent') ...[
          // Single tick
          Icon(Icons.check, size: 14, color: getColor()),
        ] else ...[
          // Double tick
          Stack(
            children: [
              Icon(Icons.check, size: 14, color: getColor()),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.check, size: 14, color: getColor()),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
