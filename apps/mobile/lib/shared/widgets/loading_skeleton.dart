import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base =
        isDark ? AppColors.surfaceVariant : const Color(0xFFE6E6EE);
    final Color highlight =
        isDark ? const Color(0xFF2A2A38) : const Color(0xFFF2F2F7);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[base, highlight, base],
          stops: const <double>[0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class AppScreenSkeleton extends StatelessWidget {
  const AppScreenSkeleton({
    super.key,
    this.showHeader = true,
    this.cardCount = 4,
    this.scrollable = true,
    this.padding,
  });

  final bool showHeader;
  final int cardCount;
  final bool scrollable;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets resolvedPadding =
        padding ?? const EdgeInsets.all(AppSpacing.md);

    final Widget content = Padding(
      padding: resolvedPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showHeader) ...<Widget>[
            const AppSkeletonBox(width: 180, height: 22, radius: 8),
            const SizedBox(height: AppSpacing.sm),
            const AppSkeletonBox(width: 120, height: 14, radius: 6),
            const SizedBox(height: AppSpacing.lg),
          ],
          for (int i = 0; i < cardCount; i++) ...<Widget>[
            const AppSkeletonBox(height: 92, radius: 16),
            if (i != cardCount - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );

    if (scrollable) {
      return ListView(children: <Widget>[content]);
    }

    return content;
  }
}
