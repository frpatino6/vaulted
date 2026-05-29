import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    );
  }
}
