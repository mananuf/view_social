import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSent;
  final bool isRead;
  final bool isDelivered;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isSent,
    this.isRead = false,
    this.isDelivered = true, // Assume delivered by default
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceLg,
        vertical: DesignTokens.spaceXs,
      ),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6A0DAD).withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: DesignTokens.spaceXs),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceLg,
                    vertical: DesignTokens.spaceMd,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSent
                        ? const LinearGradient(
                            colors: [Color(0xFF6A0DAD), Color(0xFFA500E0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSent
                        ? null
                        : (isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF3F4F6)),
                    borderRadius: isSent
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(DesignTokens.radiusXl),
                            topRight: Radius.circular(DesignTokens.radiusXl),
                            bottomLeft: Radius.circular(DesignTokens.radiusXl),
                            bottomRight: Radius.circular(DesignTokens.radiusSm),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(DesignTokens.radiusXl),
                            topRight: Radius.circular(DesignTokens.radiusXl),
                            bottomLeft: Radius.circular(DesignTokens.radiusSm),
                            bottomRight: Radius.circular(DesignTokens.radiusXl),
                          ),
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSent
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFF9FAFB)
                                : const Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSent) ...[
                      Icon(
                        // Single tick: sent but not delivered (receiver offline)
                        // Double tick: delivered (receiver online)
                        isDelivered ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead
                            ? const Color(0xFF6A0DAD) // Purple for read
                            : (isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(
                                      0xFF6B7280,
                                    )), // Gray for delivered but not read
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
