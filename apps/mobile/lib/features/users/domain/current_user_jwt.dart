import 'dart:convert';

import '../../../core/storage/auth_token_store.dart';

/// Extracts the role of the current user from the JWT without calling the API.
String? currentUserRole() {
  final token = AuthTokenStore.instance.getToken();
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  return jsonDecode(payload)['role'] as String?;
}

/// Extracts the user id (sub) of the current user from the JWT.
String? currentUserId() {
  final token = AuthTokenStore.instance.getToken();
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final sub = jsonDecode(payload)['sub'];
  return sub is String ? sub : sub?.toString();
}
