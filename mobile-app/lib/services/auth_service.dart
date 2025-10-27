import '../models/app_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _api = ApiClient();
  final TokenStorage _tokens = TokenStorage();
  Future<AppUser?> getCurrentUser() async {
    // TODO: Replace with API-backed token lookup (e.g., decode stored JWT or /me)
    return null;
  }

  Future<AppUser> signIn(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw 'Username and password are required';
    }
    // TODO: Replace endpoint and mapping with your API
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
    // TODO: Call API Gateway: POST /auth/signup
    if (username.isEmpty || password.isEmpty) {
      throw 'Username and password are required';
    }
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
