import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_user.freezed.dart';
part 'presence_user.g.dart';

@freezed
class PresenceUser with _$PresenceUser {
  const factory PresenceUser({
    required String userId,
    required String email,
    required String role,
    required String connectedAt,
    required String lastSeen,
  }) = _PresenceUser;

  factory PresenceUser.fromJson(Map<String, dynamic> json) =>
      _$PresenceUserFromJson(json);
}
