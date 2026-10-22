import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_user.dart';

/// Service managing authentication and user session state for DueMate.
class AuthService {
  AuthService() {
    _init();
  }

  static const _userSessionKey = 'duemate_auth_user_session';
  static const _registeredAccountsKey = 'duemate_registered_accounts';
  final _authStateController = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  bool _initialized = false;
  bool _useFirebaseAuth = false;

  AuthUser? get currentUser => _currentUser;
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;
  bool get isInitialized => _initialized;

  Future<void> _init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _useFirebaseAuth = true;
        fb.FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
          if (fbUser != null) {
            final user = AuthUser(
              id: fbUser.uid,
              email: fbUser.email ?? '',
              fullName:
                  fbUser.displayName ??
                  fbUser.email?.split('@').first ??
                  'User',
              createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
              photoUrl: fbUser.photoURL,
            );
            _currentUser = user;
            await _saveSession(user);
          } else {
            _currentUser = null;
            await _clearSession();
          }
          _authStateController.add(_currentUser);
        });
      } else {
        await _loadSavedSession();
      }
    } catch (_) {
      await _loadSavedSession();
    } finally {
      _initialized = true;
      _authStateController.add(_currentUser);
    }
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userSessionKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _currentUser = AuthUser.fromJson(data);
      }
    } catch (_) {
      _currentUser = null;
    }
  }

  Future<void> _saveSession(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSessionKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userSessionKey);
    } catch (_) {}
  }

  Future<Map<String, Map<String, dynamic>>> _loadRegisteredAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_registeredAccountsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
        );
      }
    } catch (_) {}
    return {};
  }

  Future<void> _saveRegisteredAccount({
    required String email,
    required String fullName,
    required String password,
    required String userId,
    required DateTime createdAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await _loadRegisteredAccounts();
      accounts[email] = {
        'id': userId,
        'email': email,
        'fullName': fullName,
        'password': password,
        'createdAt': createdAt.toIso8601String(),
      };
      await prefs.setString(_registeredAccountsKey, jsonEncode(accounts));
    } catch (_) {}
  }

  /// Register a new user with Email, Password and Full Name.
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();

    if (cleanName.isEmpty) {
      return const AuthResult.failure('Please enter your full name.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const AuthResult.failure('Please enter a valid email address.');
    }
    if (password.length < 6) {
      return const AuthResult.failure(
        'Password must be at least 6 characters long.',
      );
    }

    if (_useFirebaseAuth) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: cleanEmail,
              password: password,
            );
        final fbUser = credential.user;
        if (fbUser != null) {
          await fbUser.updateDisplayName(cleanName);
          final user = AuthUser(
            id: fbUser.uid,
            email: cleanEmail,
            fullName: cleanName,
            createdAt: DateTime.now(),
          );
          _currentUser = user;
          await _saveSession(user);
          _authStateController.add(_currentUser);
          return AuthResult.success(user);
        }
      } on fb.FirebaseAuthException catch (e) {
        return AuthResult.failure(_mapFirebaseError(e.code, e.message));
      } catch (_) {
        return const AuthResult.failure(
          'Registration failed. Please check your connection.',
        );
      }
    }

    // Local account registration with persistent credentials
    final accounts = await _loadRegisteredAccounts();
    if (accounts.containsKey(cleanEmail)) {
      return const AuthResult.failure(
        'An account already exists for this email. Please sign in.',
      );
    }

    final userId = 'user_${cleanEmail.hashCode.abs()}';
    final now = DateTime.now();
    await _saveRegisteredAccount(
      email: cleanEmail,
      fullName: cleanName,
      password: password,
      userId: userId,
      createdAt: now,
    );

    final user = AuthUser(
      id: userId,
      email: cleanEmail,
      fullName: cleanName,
      createdAt: now,
    );
    _currentUser = user;
    await _saveSession(user);
    _authStateController.add(_currentUser);
    return AuthResult.success(user);
  }

  /// Sign in with Email and Password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const AuthResult.failure('Please enter a valid email address.');
    }
    if (password.isEmpty) {
      return const AuthResult.failure('Please enter your password.');
    }

    if (_useFirebaseAuth) {
      try {
        final credential = await fb.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: cleanEmail, password: password);
        final fbUser = credential.user;
        if (fbUser != null) {
          final user = AuthUser(
            id: fbUser.uid,
            email: cleanEmail,
            fullName: fbUser.displayName ?? cleanEmail.split('@').first,
            createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
          );
          _currentUser = user;
          await _saveSession(user);
          _authStateController.add(_currentUser);
          return AuthResult.success(user);
        }
      } on fb.FirebaseAuthException catch (e) {
        return AuthResult.failure(_mapFirebaseError(e.code, e.message));
      } catch (_) {
        return const AuthResult.failure(
          'Sign in failed. Please check your credentials.',
        );
      }
    }

    // Local authentication: verify against registered accounts
    final accounts = await _loadRegisteredAccounts();
    final account = accounts[cleanEmail];
    if (account == null) {
      return const AuthResult.failure(
        'No account found for this email. Please create an account.',
      );
    }

    if (account['password'] != password) {
      return const AuthResult.failure('Invalid email or password.');
    }

    final createdAt =
        DateTime.tryParse(account['createdAt'] as String? ?? '') ??
        DateTime.now();
    final user = AuthUser(
      id: account['id'] as String? ?? 'user_${cleanEmail.hashCode.abs()}',
      email: cleanEmail,
      fullName: account['fullName'] as String? ?? cleanEmail.split('@').first,
      createdAt: createdAt,
    );

    _currentUser = user;
    await _saveSession(user);
    _authStateController.add(_currentUser);
    return AuthResult.success(user);
  }

  /// Update user full name / profile.
  Future<AuthResult> updateProfile({required String fullName}) async {
    final cleanName = fullName.trim();
    if (cleanName.isEmpty) {
      return const AuthResult.failure('Name cannot be empty.');
    }
    if (_currentUser == null) {
      return const AuthResult.failure('No user is currently signed in.');
    }

    if (_useFirebaseAuth) {
      try {
        final fbUser = fb.FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          await fbUser.updateDisplayName(cleanName);
        }
      } catch (_) {}
    }

    // Update local accounts if stored
    try {
      final accounts = await _loadRegisteredAccounts();
      final email = _currentUser!.email;
      if (accounts.containsKey(email)) {
        accounts[email]!['fullName'] = cleanName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_registeredAccountsKey, jsonEncode(accounts));
      }
    } catch (_) {}

    final updated = _currentUser!.copyWith(fullName: cleanName);
    _currentUser = updated;
    await _saveSession(updated);
    _authStateController.add(_currentUser);
    return AuthResult.success(updated);
  }

  /// Update or remove user profile photo.
  Future<AuthResult> updateProfilePhoto(String? photoUrl) async {
    if (_currentUser == null) {
      return const AuthResult.failure('No user is currently signed in.');
    }

    if (_useFirebaseAuth) {
      try {
        final fbUser = fb.FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          if (photoUrl == null ||
              photoUrl.startsWith('http://') ||
              photoUrl.startsWith('https://')) {
            await fbUser.updatePhotoURL(photoUrl);
          }
        }
      } catch (_) {}
    }

    // Update local accounts if stored
    try {
      final accounts = await _loadRegisteredAccounts();
      final email = _currentUser!.email;
      if (accounts.containsKey(email)) {
        accounts[email]!['photoUrl'] = photoUrl;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_registeredAccountsKey, jsonEncode(accounts));
      }
    } catch (_) {}

    final updated = _currentUser!.copyWith(photoUrl: photoUrl);
    _currentUser = updated;
    await _saveSession(updated);
    _authStateController.add(_currentUser);
    return AuthResult.success(updated);
  }

  /// Send a password reset email.
  Future<AuthResult> sendPasswordReset({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return const AuthResult.failure('Please enter a valid email address.');
    }

    if (_useFirebaseAuth) {
      try {
        await fb.FirebaseAuth.instance.sendPasswordResetEmail(
          email: cleanEmail,
        );
        return const AuthResult.success(null);
      } on fb.FirebaseAuthException catch (e) {
        return AuthResult.failure(_mapFirebaseError(e.code, e.message));
      } catch (_) {
        return const AuthResult.failure(
          'Failed to send reset email. Please try again.',
        );
      }
    }

    // Local authentication: verify account exists
    final accounts = await _loadRegisteredAccounts();
    if (!accounts.containsKey(cleanEmail)) {
      return const AuthResult.failure('No account found for this email.');
    }

    return const AuthResult.success(null);
  }

  /// Sign out current user.
  Future<void> signOut() async {
    if (_useFirebaseAuth) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    await _clearSession();
    _authStateController.add(null);
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return message ?? 'Authentication error occurred. Please try again.';
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

class AuthResult {
  const AuthResult.success(this.user) : error = null;
  const AuthResult.failure(this.error) : user = null;

  final AuthUser? user;
  final String? error;

  bool get isSuccess => error == null;
}
