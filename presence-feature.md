# Plan: Real-Time User Presence ("Who is Online")

**Goal**: Show which users in a tenant are genuinely online — not just logged in, but actively using the app right now.

**Definition of "online"**: User has an active WebSocket connection AND sent a heartbeat in the last 90 seconds.

---

## Key Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| Realtime transport | Socket.IO (not raw WS) | Room support, auto-reconnect, browser compat |
| Presence state store | Redis (TTL keys only) | No DB migration; ephemeral state; already global |
| "Actually online" signal | Heartbeat every 30s → Redis TTL 90s | TTL expiry = gone offline without clean disconnect |
| Tenant isolation | Redis key prefix + Socket.IO room per tenant | Staff of tenant A cannot see tenant B |
| Auth on WebSocket | JWT in handshake `auth.token` | Reuse JwtStrategy pattern, same guards |
| No DB columns | Redis is sole source of truth | No `isOnline` / `lastSeen` column needed |

**Redis key**: `presence:{tenantId}:{userId}` → TTL 90s → value = JSON `{userId, email, role, connectedAt, lastSeen}`

---

## Phase 0: Documentation Discovery ✅ DONE

**Findings that every subsequent phase must reference:**

- **Redis injection**: `@InjectRedis()` decorator from `apps/api/src/common/decorators/inject-redis.decorator.ts` — use this everywhere
- **JWT payload**: `{ sub, tenantId, email, role, mfaVerified }` — `sub` = userId
- **Global guards order** in AppModule: Throttler → JwtAuthGuard → MfaVerified → Roles → GuestExpiration
- **No WebSocket packages exist** — must add `@nestjs/platform-socket.io` + `socket.io` to `apps/api/package.json`
- **No Flutter WS packages exist** — must add `socket_io_client` to `apps/mobile/pubspec.yaml`
- **Module registration** in `apps/api/src/app.module.ts` line ~89 — add `PresenceModule` here
- **Existing module pattern** to copy: `apps/api/src/modules/dashboard/` (service + controller + module)
- **Existing Flutter feature pattern**: `apps/mobile/lib/features/maintenance/` (data/ domain/ presentation/ layers)

---

## Phase 1: Backend — Socket.IO Gateway + Redis Presence

**What to implement:**

### 1.1 Install packages
```bash
# in apps/api/
npm install @nestjs/websockets @nestjs/platform-socket.io socket.io
npm install --save-dev @types/socket.io
```

### 1.2 Create `apps/api/src/modules/presence/`

**Files to create:**
- `presence.module.ts`
- `presence.gateway.ts` — Socket.IO gateway with JWT auth on `handleConnection`
- `presence.service.ts` — Redis read/write for presence keys

**`presence.gateway.ts` — key logic:**
```typescript
@WebSocketGateway({ cors: { origin: '*' }, namespace: '/presence' })
export class PresenceGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(
    @InjectRedis() private readonly redis: Redis,
    private readonly presenceService: PresenceService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async handleConnection(client: Socket) {
    // 1. Extract JWT from client.handshake.auth.token
    // 2. Verify with JwtService + check Redis blacklist
    // 3. On invalid token: client.disconnect()
    // 4. Store payload on client.data.user
    // 5. Join room: `tenant:${tenantId}`
    // 6. Call presenceService.setOnline(tenantId, userId, userData)
    // 7. Emit to room: 'presence:user_online' with user info
  }

  async handleDisconnect(client: Socket) {
    // 1. If client.data.user exists
    // 2. Call presenceService.setOffline(tenantId, userId)
    // 3. Emit to room: 'presence:user_offline' with userId
  }

  @SubscribeMessage('heartbeat')
  async onHeartbeat(client: Socket) {
    // 1. presenceService.refreshTTL(tenantId, userId) — resets 90s TTL
    // 2. Optionally ACK back
  }
}
```

**`presence.service.ts` — key methods:**
```typescript
const PRESENCE_TTL = 90; // seconds
const key = (tenantId: string, userId: string) => `presence:${tenantId}:${userId}`;

async setOnline(tenantId, userId, data: {email, role, connectedAt}) {
  await this.redis.setex(key(tenantId, userId), PRESENCE_TTL, JSON.stringify({
    userId, tenantId, ...data, lastSeen: new Date().toISOString()
  }));
}

async setOffline(tenantId, userId) {
  await this.redis.del(key(tenantId, userId));
}

async refreshTTL(tenantId, userId) {
  await this.redis.expire(key(tenantId, userId), PRESENCE_TTL);
  // Also update lastSeen in the value
}

async getOnlineUsers(tenantId): Promise<PresenceUser[]> {
  const keys = await this.redis.keys(`presence:${tenantId}:*`);
  if (!keys.length) return [];
  const values = await this.redis.mget(...keys);
  return values.filter(Boolean).map(v => JSON.parse(v));
}
```

**`presence.module.ts`:**
```typescript
@Module({
  imports: [JwtModule.registerAsync({ ... })],  // same config as AuthModule
  providers: [PresenceGateway, PresenceService],
  exports: [PresenceService],
})
export class PresenceModule {}
```

### 1.3 Register in AppModule
Add `PresenceModule` to imports in `apps/api/src/app.module.ts`.

**⚠ Anti-patterns to avoid:**
- Do NOT use the global `JwtAuthGuard` (APP_GUARD) for WebSocket — it's designed for HTTP. Validate JWT manually in `handleConnection`.
- Do NOT use `redis.scan` in a loop for key enumeration in prod hot paths — use a sorted set OR accept the keys() scan on small tenants for MVP.
- Do NOT emit `presence:user_online` before verifying JWT is valid.

**Verification checklist:**
- [ ] `npm run build` in apps/api passes with no TypeScript errors
- [ ] Manual test: connect via socket.io client with valid JWT → key appears in Redis
- [ ] Manual test: disconnect → key deleted from Redis
- [ ] Manual test: connect, wait 91s without heartbeat → key expires
- [ ] Manual test: send heartbeat every 30s → key stays alive

---

## Phase 2: Backend — REST Endpoint for Initial Load

**What to implement:**

### 2.1 Add REST controller to presence module

**`presence.controller.ts`:**
```typescript
@Controller('presence')
export class PresenceController {
  constructor(private readonly presenceService: PresenceService) {}

  @Get('online')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  async getOnlineUsers(@CurrentUser() user: JwtPayload) {
    return this.presenceService.getOnlineUsers(user.tenantId);
  }
}
```

Response shape:
```json
[
  {
    "userId": "uuid",
    "email": "user@example.com",
    "role": "manager",
    "connectedAt": "2026-04-17T20:00:00Z",
    "lastSeen": "2026-04-17T20:01:30Z"
  }
]
```

### 2.2 Wrap in `ResponseInterceptor` (automatic via global interceptor)

**Verification checklist:**
- [ ] `GET /presence/online` returns array (may be empty if no WS connections)
- [ ] Returns 401 without JWT
- [ ] Staff can call endpoint (their own tenant)
- [ ] Tenant isolation: user of tenant A cannot see tenant B users

---

## Phase 3: Flutter — WebSocket Client + Riverpod State

**What to implement:**

### 3.1 Add package
```yaml
# apps/mobile/pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

### 3.2 Create `apps/mobile/lib/features/presence/`

**Layer structure (follow existing feature pattern):**
```
presence/
  data/
    presence_remote_data_source.dart   # REST call: GET /presence/online
    presence_socket_service.dart       # Socket.IO connection management
    presence_repository.dart
  domain/
    presence_user.dart                 # Freezed model
  presentation/
    providers/
      presence_provider.dart           # Riverpod AsyncNotifier
    widgets/
      online_indicator.dart            # Small green dot widget
      online_users_count.dart          # "N online" badge widget
```

### 3.3 `presence_socket_service.dart` — key logic
```dart
class PresenceSocketService {
  IO.Socket? _socket;
  Timer? _heartbeatTimer;

  void connect(String accessToken) {
    _socket = IO.io(
      AppConfig.apiBaseUrl,
      IO.OptionBuilder()
        .setNamespace('/presence')
        .setTransports(['websocket'])
        .setAuth({'token': accessToken})
        .disableAutoConnect()
        .build(),
    );

    _socket!.connect();

    _socket!.on('connect', (_) {
      _startHeartbeat();
    });

    _socket!.on('presence:user_online', (data) {
      // notify PresenceNotifier → add user to list
    });

    _socket!.on('presence:user_offline', (data) {
      // notify PresenceNotifier → remove user from list
    });

    _socket!.on('disconnect', (_) {
      _heartbeatTimer?.cancel();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _socket?.emit('heartbeat'),
    );
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _socket?.disconnect();
    _socket = null;
  }
}
```

### 3.4 `presence_provider.dart`
```dart
@riverpod
class PresenceNotifier extends _$PresenceNotifier {
  // Initial state: load from REST GET /presence/online
  // Then update reactively from socket events
  // Connect socket on first build
  // Disconnect in dispose
}
```

### 3.5 Connect/disconnect lifecycle
- Connect in `AuthNotifier` after successful login (pass new access token)
- Disconnect in `AuthNotifier` on logout
- On token refresh: reconnect with new token (call `disconnect()` then `connect(newToken)`)

**⚠ Anti-patterns to avoid:**
- Do NOT store the socket in Riverpod state — keep it in the service singleton
- Do NOT reconnect on every widget rebuild — manage lifecycle at auth layer
- Do NOT show online count from socket events alone — seed from REST call first

**Verification checklist:**
- [ ] Socket connects after login, disconnects after logout
- [ ] `flutter pub get` succeeds
- [ ] Heartbeat timer fires every 30s (verify with debug logs)
- [ ] `PresenceNotifier` state updates when another user connects (manual test with two devices)

---

## Phase 4: Flutter — UI Integration

**What to implement:**

### 4.1 Online indicator widget
Small green dot that appears next to a user's avatar/name when they are online.

```dart
// apps/mobile/lib/features/presence/presentation/widgets/online_indicator.dart
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  // Renders: green circle (8px) if online, grey otherwise
}
```

Usage:
```dart
// In UsersListScreen user tile:
Stack(
  children: [
    UserAvatar(user: user),
    Positioned(
      bottom: 0, right: 0,
      child: OnlineIndicator(isOnline: presenceState.isOnline(user.id)),
    ),
  ],
)
```

### 4.2 Dashboard online count badge
Add `OnlineUsersCount` widget to Dashboard screen.

```dart
// Small card: "3 online now" with green pulse indicator
// Reads from: ref.watch(presenceNotifierProvider)
// Taps to: UsersScreen filtered to online only
```

### 4.3 Users screen integration
- In `apps/mobile/lib/features/users/presentation/screens/users_list_screen.dart`
- Add `OnlineIndicator` to each user tile
- Add filter chip: "All" / "Online"

**Verification checklist:**
- [ ] Green dot appears next to users who are online
- [ ] Dot disappears within ~5s when a user disconnects (socket event)
- [ ] Dashboard shows correct online count
- [ ] Filter "Online" shows only users with active presence

---

## Phase 5: Integration & Hardening

**What to implement:**

### 5.1 Handle token refresh in Flutter
When `_AuthInterceptor` refreshes the access token (401 retry flow), call:
```dart
presenceSocketService.reconnect(newAccessToken);
```
So the socket uses the fresh token and doesn't get kicked on next server-side validation.

### 5.2 Throttle presence events in gateway
Prevent presence spam on rapid connect/disconnect (add debounce or minimum interval):
```typescript
// In handleConnection: only emit presence:user_online if user was previously offline
const wasOnline = await this.redis.exists(key(tenantId, userId));
if (!wasOnline) {
  this.server.to(`tenant:${tenantId}`).emit('presence:user_online', userData);
}
```

### 5.3 Graceful app lifecycle
Flutter app going to background → send disconnect or stop heartbeat:
```dart
// In AppLifecycleObserver:
case AppLifecycleState.paused:
  presenceSocketService.pauseHeartbeat();  // stop timer but keep connection
case AppLifecycleState.resumed:
  presenceSocketService.resumeHeartbeat(); // restart timer + emit heartbeat immediately
```

### 5.4 RBAC scoping
- Owner/Manager: see ALL users in tenant
- Staff: see only users assigned to same properties
- Auditor: see online count only (no names)
- Guest: no presence access

Enforce in `PresenceController.getOnlineUsers()` and filter socket room events.

**Verification checklist:**
- [ ] Reconnect after token refresh works without manual re-login
- [ ] App going to background → comes back → still shows correct state
- [ ] Staff cannot see users from other properties
- [ ] No socket.io memory leaks (check dart:developer timeline)

---

## Build Order

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
(backend)  (REST)   (flutter) (flutter)  (hardening)
```

Each phase is independently deployable. Phase 2 can be tested via curl before Flutter exists.

---

## Files to Create / Modify

### Backend (new files)
```
apps/api/src/modules/presence/presence.module.ts
apps/api/src/modules/presence/presence.gateway.ts
apps/api/src/modules/presence/presence.service.ts
apps/api/src/modules/presence/presence.controller.ts
apps/api/src/modules/presence/dto/presence-user.dto.ts
```

### Backend (modified)
```
apps/api/src/app.module.ts          ← add PresenceModule import
apps/api/package.json               ← add socket.io packages
```

### Flutter (new files)
```
apps/mobile/lib/features/presence/data/presence_socket_service.dart
apps/mobile/lib/features/presence/data/presence_remote_data_source.dart
apps/mobile/lib/features/presence/data/presence_repository.dart
apps/mobile/lib/features/presence/domain/presence_user.dart
apps/mobile/lib/features/presence/presentation/providers/presence_provider.dart
apps/mobile/lib/features/presence/presentation/widgets/online_indicator.dart
apps/mobile/lib/features/presence/presentation/widgets/online_users_count.dart
```

### Flutter (modified)
```
apps/mobile/pubspec.yaml                              ← add socket_io_client
apps/mobile/lib/features/auth/data/auth_notifier.dart ← connect/disconnect socket
apps/mobile/lib/features/users/presentation/screens/users_list_screen.dart ← online indicators
apps/mobile/lib/features/dashboard/presentation/screens/dashboard_screen.dart ← online count
```
