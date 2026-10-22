import 'package:equatable/equatable.dart';

/// Immutable entity representing an authenticated user in DueMate.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? photoUrl;

  AuthUser copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? createdAt,
    Object? photoUrl = _sentinel,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: identical(photoUrl, _sentinel)
          ? this.photoUrl
          : photoUrl as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'createdAt': createdAt.toIso8601String(),
    'photoUrl': photoUrl,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String? ?? 'User',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    photoUrl: json['photoUrl'] as String?,
  );

  @override
  List<Object?> get props => [id, email, fullName, createdAt, photoUrl];

  static const Object _sentinel = Object();
}
