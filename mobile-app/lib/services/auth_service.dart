import '../models/app_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Development bypass flag - set to false when real auth is configured
const bool _bypassAuth = true;

/// Default development credentials
const String _defaultUsername = 'testuser';
const String _defaultPassword = 'testpass123';

class AuthService {
  final ApiClient _api = ApiClient();
  final TokenStorage _tokens = TokenStorage();

  Future<AppUser?> getCurrentUser() async {
    if (_bypassAuth) {
      // In bypass mode, check if we have a stored token (from previous sessions)
      final token = await _tokens.getAccessToken();
      if (token != null && token.isNotEmpty) {
        return const AppUser(
          id: 'dev-user-1',
          username: _defaultUsername,
          email: 'testuser@example.com',
        );
      }
      return null;
    }
    // TODO: Replace with API-backed token lookup (e.g., decode stored JWT or /me)
    return null;
  }

  Future<AppUser> signIn(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw 'Username and password are required';
    }

    // Development bypass mode - accepts default credentials
    if (_bypassAuth) {
      // Accept any credentials or validate against defaults
      if (username == _defaultUsername && password == _defaultPassword) {
        // Save a dummy token for session persistence
        await _tokens.saveTokens(
          accessToken: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
        );
        return const AppUser(
          id: 'dev-user-1',
          username: _defaultUsername,
          email: 'testuser@example.com',
        );
      }
      // In bypass mode, accept any credentials for convenience
      await _tokens.saveTokens(
        accessToken: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
      );
      return AppUser(
        id: 'dev-user-${username.hashCode}',
        username: username,
        email: '$username@example.com',
      );
    }

    // Real API authentication
    final resp = await _api.post<Map<String, dynamic>>('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access != null) {
      await _tokens.saveTokens(accessToken: access, refreshToken: refresh);
    }
    return AppUser(
      id: (data['user']?['id'] ?? username).toString(),
      username: data['user']?['username']?.toString() ?? username,
      email: data['user']?['email']?.toString(),
    );
  }

  Future<AppUser> signUp(String username, String email, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw 'Username and password are required';
    }

    // Development bypass mode
    if (_bypassAuth) {
      await _tokens.saveTokens(
        accessToken: 'dev-token-${DateTime.now().millisecondsSinceEpoch}',
      );
      return AppUser(
        id: 'dev-user-${username.hashCode}',
        username: username,
        email: email,
      );
    }

    // TODO: Call API Gateway: POST /auth/signup
    return AppUser(id: 'temp-id', username: username, email: email);
  }

  Future<void> signOut() async {
    await _tokens.clear();
  }

  Future<void> confirmSignUp(String username, String confirmationCode) async {
    // TODO: Call API Gateway: POST /auth/confirm
    return;
  }

  Future<void> resendSignUpCode(String username) async {
    // TODO: Call API Gateway: POST /auth/resend
    return;
  }

  Future<void> forgotPassword(String username) async {
    // TODO: Call API Gateway: POST /auth/forgot
    return;
  }

  Future<void> confirmPassword(
      String username, String newPassword, String confirmationCode) async {
    // TODO: Call API Gateway: POST /auth/reset/confirm
    return;
  }
}
