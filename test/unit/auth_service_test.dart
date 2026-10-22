import 'package:duemate/core/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService local persistent authentication', () {
    test('signUp creates user account and signs in', () async {
      final auth = AuthService();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await auth.register(
        email: 'test@duemate.app',
        password: 'securepassword123',
        fullName: 'Jane Doe',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user, isNotNull);
      expect(result.user!.email, 'test@duemate.app');
      expect(result.user!.fullName, 'Jane Doe');
      expect(auth.currentUser?.email, 'test@duemate.app');
    });

    test('signUp rejects duplicate emails', () async {
      final auth = AuthService();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await auth.register(
        email: 'duplicate@duemate.app',
        password: 'password123',
        fullName: 'First User',
      );

      final secondResult = await auth.register(
        email: 'duplicate@duemate.app',
        password: 'differentpassword',
        fullName: 'Second User',
      );

      expect(secondResult.isSuccess, isFalse);
      expect(secondResult.error, contains('already exists'));
    });

    test(
      'signIn authenticates with correct credentials and rejects incorrect',
      () async {
        final auth = AuthService();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await auth.register(
          email: 'login@duemate.app',
          password: 'correctpassword',
          fullName: 'Login User',
        );
        await auth.signOut();
        expect(auth.currentUser, isNull);

        // Wrong password
        final failResult = await auth.signIn(
          email: 'login@duemate.app',
          password: 'wrongpassword',
        );
        expect(failResult.isSuccess, isFalse);
        expect(failResult.error, contains('Invalid email or password'));
        expect(auth.currentUser, isNull);

        // Correct password
        final successResult = await auth.signIn(
          email: 'login@duemate.app',
          password: 'correctpassword',
        );
        expect(successResult.isSuccess, isTrue);
        expect(auth.currentUser?.email, 'login@duemate.app');
      },
    );

    test(
      'updateProfile updates currentUser name and preserves it across reloads',
      () async {
        final auth = AuthService();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await auth.register(
          email: 'update@duemate.app',
          password: 'password123',
          fullName: 'Original Name',
        );

        await auth.updateProfile(fullName: 'Updated Name');
        expect(auth.currentUser?.fullName, 'Updated Name');

        // Create new instance simulating app restart
        final authRestart = AuthService();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(authRestart.currentUser?.fullName, 'Updated Name');
      },
    );

    test('signOut clears active user session', () async {
      final auth = AuthService();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await auth.register(
        email: 'logout@duemate.app',
        password: 'password123',
        fullName: 'Logout User',
      );
      expect(auth.currentUser, isNotNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);

      // Verify on restart that user remains signed out
      final authRestart = AuthService();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(authRestart.currentUser, isNull);
    });
  });
}
