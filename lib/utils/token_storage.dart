import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = "jwt_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _loginTimeKey = "login_time";

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save Refresh token
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// Get Refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Remove JWT token (Logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Remove Refresh token
  static Future<void> clearRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
  }

  /// Save login time
  static Future<void> saveLoginTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTimeKey, time);
  }

  /// Get login time
  static Future<String?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginTimeKey);
  }

  /// Clear login time
  static Future<void> clearLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginTimeKey);
  }

  /// Clear all stored data (complete logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_loginTimeKey);
  }
}
