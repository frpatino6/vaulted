import 'package:flutter_test/flutter_test.dart';
import 'package:vaulted/features/ai_scan/presentation/price_parser.dart';

void main() {
  group('parsePrice', () {
    test('parses currency-formatted decimal prices', () {
      expect(parsePrice('1,499.99'), 1499.99);
      expect(parsePrice(r'$1499.99'), 1499.99);
      expect(parsePrice('1499'), 1499);
      expect(parsePrice(''), 0);
    });
  });
}
