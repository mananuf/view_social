import 'package:flutter/material.dart';

/// Online status indicator dot
class OnlineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  final bool showBorder;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Success green
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              )
            : null,
      ),
    );
  }
}

/// Avatar with online status indicator
class AvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool isOnline;
  final Color? backgroundColor;

  const AvatarWithStatus({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 48,
    this.isOnline = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor:
              backgroundColor ?? const Color(0xFF6A0DAD).withValues(alpha: 0.1),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: size / 2.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: OnlineStatusIndicator(isOnline: isOnline, size: size / 4),
          ),
      ],
    );
  }
}
