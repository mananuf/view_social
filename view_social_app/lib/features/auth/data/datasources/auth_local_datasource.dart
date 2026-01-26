import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  AuthLocalDataSourceImpl({required this.sharedPreferences});
  
  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      sharedPreferences.setString(AppConstants.accessTokenKey, accessToken),
      sharedPreferences.setString(AppConstants.refreshTokenKey, refreshToken),
    ]);
  }
  
  @override
  Future<String?> getAccessToken() async {
    return sharedPreferences.getString(AppConstants.accessTokenKey);
  }
  
  @override
  Future<String?> getRefreshToken() async {
    return sharedPreferences.getString(AppConstants.refreshTokenKey);
  }
  
  @override
  Future<void> clearTokens() async {
    await Future.wait([
      sharedPreferences.remove(AppConstants.accessTokenKey),
      sharedPreferences.remove(AppConstants.refreshTokenKey),
    ]);
  }
  
  @override
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await sharedPreferences.setString(AppConstants.userDataKey, userJson);
  }
  
  @override
  Future<UserModel?> getUser() async {
    final userJson = sharedPreferences.getString(AppConstants.userDataKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }
    return null;
  }
  
  @override
  Future<void> clearUser() async {
    await sharedPreferences.remove(AppConstants.userDataKey);
  }
}