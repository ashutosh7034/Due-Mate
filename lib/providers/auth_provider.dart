import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_service.dart';
import '../core/auth/auth_user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(service.dispose);
  return service;
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).value ??
      ref.watch(authServiceProvider).currentUser;
});
