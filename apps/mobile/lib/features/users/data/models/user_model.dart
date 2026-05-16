import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    required String role,
    required bool isActive,
    required String status,
    required bool mfaEnabled,
    @Default([]) List<String> propertyIds,
    String? lastLogin,
    String? expiresAt,
    String? createdAt,
  }) = _UserModel;


  String get name {
    final part = email.split('@').first;
    if (part.isEmpty) return email;
    return part[0].toUpperCase() + part.substring(1);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
