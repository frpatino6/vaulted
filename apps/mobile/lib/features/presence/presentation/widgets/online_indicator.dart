import 'package:flutter/material.dart';

/// Small green dot (8 px) indicating real-time presence.
/// Shows grey when offline.
class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key, required this.isOnline, this.size = 10.0});

  final bool isOnline;
  final double size;

  static const _green = Color(0xFF39FF14);
  static const _grey = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? _green : _grey;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: _green.withValues(alpha: 0.55),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
