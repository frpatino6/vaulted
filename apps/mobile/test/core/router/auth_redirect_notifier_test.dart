import 'package:flutter_test/flutter_test.dart';

import 'package:vaulted/core/router/auth_redirect_notifier.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthRedirectNotifier', () {
    test('is a ChangeNotifier', () {
      final notifier = AuthRedirectNotifier();
      expect(notifier, isNotNull);
      notifier.dispose();
    });

    test('notifyAuthLost calls notifyListeners — listeners are triggered', () {
      final notifier = AuthRedirectNotifier();
      int callCount = 0;

      notifier.addListener(() {
        callCount++;
      });

      notifier.notifyAuthLost();

      expect(callCount, 1);
      notifier.dispose();
    });

    test('multiple calls to notifyAuthLost each trigger listeners', () {
      final notifier = AuthRedirectNotifier();
      int callCount = 0;

      notifier.addListener(() {
        callCount++;
      });

      notifier.notifyAuthLost();
      notifier.notifyAuthLost();
      notifier.notifyAuthLost();

      expect(callCount, 3);
      notifier.dispose();
    });

    test('multiple listeners are all notified on notifyAuthLost', () {
      final notifier = AuthRedirectNotifier();
      final called = <String>[];

      notifier.addListener(() => called.add('listener-1'));
      notifier.addListener(() => called.add('listener-2'));
      notifier.addListener(() => called.add('listener-3'));

      notifier.notifyAuthLost();

      expect(called, containsAll(['listener-1', 'listener-2', 'listener-3']));
      notifier.dispose();
    });

    test('removed listener is not triggered after removeListener', () {
      final notifier = AuthRedirectNotifier();
      int callCount = 0;

      void listener() => callCount++;

      notifier.addListener(listener);
      notifier.notifyAuthLost();
      expect(callCount, 1);

      notifier.removeListener(listener);
      notifier.notifyAuthLost();
      expect(callCount, 1); // should not increase

      notifier.dispose();
    });

    test('no listeners causes no errors when notifyAuthLost is called', () {
      final notifier = AuthRedirectNotifier();

      expect(() => notifier.notifyAuthLost(), returnsNormally);

      notifier.dispose();
    });
  });
}
