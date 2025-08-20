import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
  Future<AuthUser?> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } catch (e) {
      // User not signed in
      return null;
    }
  }

  Future<AuthUser> signIn(String username, String password) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AuthUser> signUp(String username, String email, String password) async {
    try {
      final result = await Amplify.Auth.signUp(
        username: username,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
          },
        ),
      );
      
      // Auto-confirm the user (for development)
      // In production, you should implement email verification
      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        await Amplify.Auth.confirmSignUp(
          username: username,
          confirmationCode: '123456', // Default code for development
        );
      }
      
      return result.user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> confirmSignUp(String username, String confirmationCode) async {
    try {
      await Amplify.Auth.confirmSignUp(
        username: username,
        confirmationCode: confirmationCode,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> resendSignUpCode(String username) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: username);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> forgotPassword(String username) async {
    try {
      await Amplify.Auth.resetPassword(username: username);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> confirmPassword(String username, String newPassword, String confirmationCode) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(dynamic exception) {
    if (exception is AuthException) {
      switch (exception.type) {
        case AuthExceptionType.userNotFound:
          return 'User not found. Please check your username.';
        case AuthExceptionType.notAuthorized:
          return 'Invalid username or password.';
        case AuthExceptionType.invalidPassword:
          return 'Password does not meet requirements.';
        case AuthExceptionType.usernameExists:
          return 'Username already exists.';
        case AuthExceptionType.codeMismatch:
          return 'Invalid confirmation code.';
        case AuthExceptionType.codeExpired:
          return 'Confirmation code has expired.';
        case AuthExceptionType.limitExceeded:
          return 'Too many attempts. Please try again later.';
        default:
          return 'Authentication error: ${exception.message}';
      }
    }
    return 'An unexpected error occurred: $exception';
  }
}
