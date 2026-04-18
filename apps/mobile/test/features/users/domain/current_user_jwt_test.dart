import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:vaulted/core/storage/auth_token_store.dart';
import 'package:vaulted/features/users/domain/current_user_jwt.dart';

String _jwt(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode(jsonEncode(<String, dynamic>{'alg': 'none'})));
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return '$header.$payload.signature';
}

void main() {
  final tokenStore = AuthTokenStore.instance;

  tearDown(tokenStore.clear);

  group('currentUserRole', () {
    test('returns null when no token', () {
      tokenStore.clear();
      expect(currentUserRole(), isNull);
    });

    test('returns null when token is not a JWT', () {
      tokenStore.setToken('not-a-jwt');
      expect(currentUserRole(), isNull);
    });

    test('returns role from payload', () {
      tokenStore.setToken(_jwt(<String, dynamic>{'role': 'manager', 'sub': 'u1'}));
      expect(currentUserRole(), 'manager');
    });
  });

  group('currentUserId', () {
    test('returns null when no token', () {
      tokenStore.clear();
      expect(currentUserId(), isNull);
    });

    test('returns sub as string when sub is string', () {
      tokenStore.setToken(_jwt(<String, dynamic>{'sub': 'user-abc', 'role': 'owner'}));
      expect(currentUserId(), 'user-abc');
    });

    test('returns sub as string when sub is numeric', () {
      tokenStore.setToken(_jwt(<String, dynamic>{'sub': 42, 'role': 'staff'}));
      expect(currentUserId(), '42');
    });
  });
}
