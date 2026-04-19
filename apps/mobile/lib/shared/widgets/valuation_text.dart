import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/privacy/privacy_mode_provider.dart';

class ValuationText extends ConsumerWidget {
  const ValuationText({
    super.key,
    required this.value,
    this.currency = 'USD',
    this.style,
    this.whenNull = '—',
  });

  final num? value;
  final String currency;
  final TextStyle? style;
  final String whenNull;

  static final _fmt = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider).valueOrNull ?? false;
    final text = isPrivate
        ? '●●●●●'
        : (value != null && value! > 0 ? _fmt.format(value!.toDouble()) : whenNull);
    return Text(text, style: style);
  }
}
