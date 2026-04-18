import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/presence_user.dart';
import 'presence_remote_data_source.dart';

class PresenceRepository {
  PresenceRepository(this._remote);

  final PresenceRemoteDataSource _remote;

  Future<List<PresenceUser>> getOnlineUsers() => _remote.getOnlineUsers();
  Future<int> getOnlineCount() => _remote.getOnlineCount();
}

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(ref.watch(presenceRemoteDataSourceProvider));
});
