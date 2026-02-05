import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String? avatarUrl;
  final int unreadCount;
  final bool hasStatus;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  const ChatTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.avatarUrl,
    this.unreadCount = 0,
    this.hasStatus = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(name),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return false;
      },
      background: Container(
        color: Colors.transparent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onArchive,
              child: Container(
                width: 80,
                height: double.infinity,
                color: const Color(0xFF3B82F6),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.archive, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Archive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 80,
                height: double.infinity,
                color: const Color(0xFFEF4444),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.white, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: isSelected
            ? (isDark
                  ? const Color(0xFF6A0DAD).withOpacity(0.2)
                  : const Color(0xFF6A0DAD).withOpacity(0.1))
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceLg,
              vertical: DesignTokens.spaceMd,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF6A0DAD).withOpacity(0.1),
                      child: avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                    if (hasStatus)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Row(
                            children: [
                              Text(
                                time,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: unreadCount > 0
                                      ? theme.colorScheme.primary
                                      : (isDark
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF6B7280)),
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: DesignTokens.spaceSm),
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF6A0DAD),
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
