import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../data/presence_repository.dart';
import '../../data/presence_socket_service.dart';
import '../../domain/presence_user.dart';

/// Immutable presence state.
class PresenceState {
  const PresenceState({
    this.onlineUsers = const [],
    this.onlineCount = 0,
    this.isAuditorView = false,
  });

  final List<PresenceUser> onlineUsers;

  /// Used when role == auditor (server returns count only).
  final int onlineCount;
  final bool isAuditorView;

  int get count => isAuditorView ? onlineCount : onlineUsers.length;
  bool isOnline(String userId) =>
      onlineUsers.any((u) => u.userId == userId);

  PresenceState copyWith({
    List<PresenceUser>? onlineUsers,
    int? onlineCount,
    bool? isAuditorView,
  }) {
    return PresenceState(
      onlineUsers: onlineUsers ?? this.onlineUsers,
      onlineCount: onlineCount ?? this.onlineCount,
      isAuditorView: isAuditorView ?? this.isAuditorView,
    );
  }
}

class PresenceNotifier extends AsyncNotifier<PresenceState> {
  StreamSubscription<dynamic>? _eventSub;

  @override
  Future<PresenceState> build() async {
    ref.onDispose(_dispose);
    return const PresenceState();
  }

  /// Call after successful login/mfa-verify with the fresh access token.
  Future<void> initialize(String accessToken) async {
    // Seed from REST first
    await _loadFromRest();

    // Subscribe to socket events
    _eventSub?.cancel();
    _eventSub = ref
        .read(presenceSocketEventStreamProvider)
        .listen(_handleSocketEvent);
    // Connect socket
    ref
        .read(presenceSocketServiceProvider)
        .connect(accessToken, AppConfig.wsBaseUrl);
  }

  /// Call when Dio interceptor refreshes the access token.
  void reconnectWithToken(String accessToken) {
    ref
        .read(presenceSocketServiceProvider)
        .reconnect(accessToken, AppConfig.wsBaseUrl);
  }

  void pauseHeartbeat() =>
      ref.read(presenceSocketServiceProvider).pauseHeartbeat();

  void resumeHeartbeat() =>
      ref.read(presenceSocketServiceProvider).resumeHeartbeat();

  Future<void> refreshFromRest() => _loadFromRest();

  Future<void> _loadFromRest() async {
    try {
      final users =
          await ref.read(presenceRepositoryProvider).getOnlineUsers();
      state = AsyncData(state.valueOrNull?.copyWith(onlineUsers: users) ??
          PresenceState(onlineUsers: users));
    } on Exception catch (e) {
      // Ignore if current role is auditor; fall through to count
      try {
        final count =
            await ref.read(presenceRepositoryProvider).getOnlineCount();
        state = AsyncData(PresenceState(
          onlineCount: count,
          isAuditorView: true,
        ));
      } on Exception {
        state = AsyncError(e, StackTrace.current);
      }
    }
  }

  void _handleSocketEvent(PresenceSocketEvent event) {
    if (event.type == 'connected') {
      _loadFromRest();
    } else if (event.type == 'online') {
      _loadFromRest(); // Re-seed from REST to get full profile
    } else if (event.type == 'offline') {
      final userId = event.userId;
      if (userId == null) return;
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(current.copyWith(
        onlineUsers: current.onlineUsers
            .where((u) => u.userId != userId)
            .toList(),
      ));
    }
  }

  void _dispose() {
    _eventSub?.cancel();
    // Socket disconnected by presenceSocketServiceProvider.onDispose
  }
}

final presenceNotifierProvider =
    AsyncNotifierProvider<PresenceNotifier, PresenceState>(
  PresenceNotifier.new,
);

/// Convenience: derive current user's token from store for socket auth.
String? currentAccessToken() => AuthTokenStore.instance.getToken();
