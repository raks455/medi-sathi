import '../../domain/entities/user.dart';

/// Matches the API's TokenResponse:
/// { access_token, refresh_token, token_type, user_id, email, full_name }
class AuthSessionModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String fullName;

  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.fullName,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: json['user_id'].toString(),
      email: json['email'] as String,
      fullName: (json['full_name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user_id': userId,
        'email': email,
        'full_name': fullName,
      };

  AuthSessionModel copyWith({
    String? accessToken,
    String? refreshToken,
    String? fullName,
  }) {
    return AuthSessionModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId,
      email: email,
      fullName: fullName ?? this.fullName,
    );
  }

  User toUser() => User(id: userId, email: email, fullName: fullName);
}
