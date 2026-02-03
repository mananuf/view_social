import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/models/auth_models.dart';

class AuthService {
  static const AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  const AuthService._internal();

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get current user data from storage
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString(AppConstants.userDataKey);

    if (userDataJson != null) {
      try {
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        return User.fromJson(userData);
      } catch (e) {
        // If there's an error parsing user data, clear it
        await clearAuthData();
        return null;
      }
    }

    return null;
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  /// Check if token is expired (basic check)
  Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      // Basic JWT expiration check
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return true;
    }
  }
}
