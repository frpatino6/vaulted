import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../domain/presence_user.dart';

class PresenceRemoteDataSource {
  PresenceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PresenceUser>> getOnlineUsers() async {
    final response = await _dio.get<Map<String, dynamic>>('presence/online');
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception('Unexpected response from presence/online');
    }
    final data = body['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PresenceUser.fromJson)
          .toList();
    }
    // Auditor receives { onlineCount: N }
    return [];
  }

  Future<int> getOnlineCount() async {
    final response = await _dio.get<Map<String, dynamic>>('presence/online');
    final body = response.data;
    if (body == null || body['success'] != true) return 0;
    final data = body['data'];
    if (data is Map && data.containsKey('onlineCount')) {
      return (data['onlineCount'] as num?)?.toInt() ?? 0;
    }
    if (data is List) return data.length;
    return 0;
  }
}

final presenceRemoteDataSourceProvider =
    Provider<PresenceRemoteDataSource>((ref) {
  return PresenceRemoteDataSource(ref.watch(apiClientProvider).dio);
});
