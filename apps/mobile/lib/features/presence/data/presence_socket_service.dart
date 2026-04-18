import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Manages the Socket.IO connection for presence events.
/// Lifecycle: connect on login, disconnect on logout.
/// One singleton per ProviderScope.
class PresenceSocketService {
  PresenceSocketService(this._ref);

  final Ref _ref;
  io.Socket? _socket;
  Timer? _heartbeatTimer;

  bool get isConnected => _socket?.connected == true;

  void connect(String accessToken, String wsBaseUrl) {
    _socket?.dispose();
    _heartbeatTimer?.cancel();

    // In socket_io_client v2 the namespace is part of the URL.
    final url = wsBaseUrl.endsWith('/')
        ? '${wsBaseUrl}presence'
        : '$wsBaseUrl/presence';

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      _startHeartbeat();
      _ref.read(_presenceSocketEventProvider).add(PresenceSocketEvent.connected());
    });

    _socket!.on('connect_error', (data) {
      _heartbeatTimer?.cancel();
    });

    _socket!.on('disconnect', (_) {
      _heartbeatTimer?.cancel();
    });

    _socket!.on('presence:user_online', (data) {
      final userId = _extractUserId(data);
      if (userId != null) {
        _ref.read(_presenceSocketEventProvider).add(PresenceSocketEvent.userOnline(userId));
      }
    });

    _socket!.on('presence:user_offline', (data) {
      final userId = _extractUserId(data);
      if (userId != null) {
        _ref.read(_presenceSocketEventProvider).add(PresenceSocketEvent.userOffline(userId));
      }
    });

    _socket!.connect();
  }

  void reconnect(String accessToken, String wsBaseUrl) {
    disconnect();
    connect(accessToken, wsBaseUrl);
  }

  void pauseHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void resumeHeartbeat() {
    _heartbeatTimer?.cancel();
    _socket?.emit('heartbeat');
    _startHeartbeat();
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _socket?.emit('heartbeat'),
    );
  }

  static String? _extractUserId(dynamic data) {
    if (data is Map) {
      final v = data['userId'];
      return v is String ? v : v?.toString();
    }
    return null;
  }
}

// --------------------------------------------------------------------------
// Internal event bus used to pipe socket events into Riverpod state
// --------------------------------------------------------------------------

/// Socket presence event exposed to PresenceNotifier.
class PresenceSocketEvent {
  PresenceSocketEvent.connected() : type = 'connected', userId = null;
  PresenceSocketEvent.userOnline(String id) : type = 'online', userId = id;
  PresenceSocketEvent.userOffline(String id) : type = 'offline', userId = id;

  final String type;
  final String? userId;
}

// StreamController kept as a provider so it is disposed with the container.
final _presenceSocketEventProvider =
    Provider<StreamController<PresenceSocketEvent>>((ref) {
  final ctrl = StreamController<PresenceSocketEvent>.broadcast();
  ref.onDispose(ctrl.close);
  return ctrl;
});

/// Public stream of socket events consumed by [PresenceNotifier].
final presenceSocketEventStreamProvider =
    Provider<Stream<PresenceSocketEvent>>((ref) {
  return ref.watch(_presenceSocketEventProvider).stream;
});

final presenceSocketServiceProvider = Provider<PresenceSocketService>((ref) {
  final svc = PresenceSocketService(ref);
  ref.onDispose(svc.disconnect);
  return svc;
});
