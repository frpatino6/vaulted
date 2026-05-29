import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class HelpScreenButton extends StatelessWidget {
  const HelpScreenButton({super.key, required this.screenKey});

  final String screenKey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline_rounded),
      tooltip: 'Guide',
      onPressed: () =>
          context.push('/help-chat?screen=$screenKey&ask=Explain this screen'),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
      ),
    );
  }
}
