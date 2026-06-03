import 'package:amplify_flutter/amplify_flutter.dart';

abstract class AuthRepository {
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<SignUpResult> confirmSignUp({
    required String username,
    required String confirmationCode,
  });

  Future<void> resendSignUpCode({required String username});

  Future<SignInResult> signIn({
    required String username,
    required String password,
  });

  Future<void> signOut();

  Future<List<AuthUserAttribute>> getCurrentUserAttributes();

  Future<void> resetPassword({required String username});

  Future<void> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  });
}