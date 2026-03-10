// Basic smoke test for Vaulted app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vaulted/main.dart';

void main() {
  testWidgets('App loads and shows login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VaultedApp(),
      ),
    );

    expect(find.text('Vaulted'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
