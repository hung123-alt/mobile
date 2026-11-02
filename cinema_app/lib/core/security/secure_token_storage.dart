import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LOP 3 - LUU TOKEN AN TOAN.
///
/// VÌ SAO TACH 2 NOI LUU TRU?
/// - Mobile khac web: khong co cookie HttpOnly. Neu luu token vao
///   SharedPreferences (XML khong ma hoa) thi may root/bi mat trom
///   se doc duoc token dang plaintext.
/// - Token/refresh_token/secret -> luu o Keychain (iOS) /
///   EncryptedSharedPreferences (Android) qua `flutter_secure_storage`.
/// - Cai khong nhay cam (theme_mode) -> giu o SharedPreferences cho nhe.
///
/// QUY TAC:
/// - KHONG luu token vao bien static toan cuc (tien trinh bi dump la lo).
/// - Moi doc/ghi deu qua class nay (Future), loi I/O bat o ranh gioi.
class SecureTokenStorage {
  SecureTokenStorage._();

  // Keychain (iOS) + EncryptedSharedPreferences (Android).
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _kAccessToken = 'secure_access_token';
  static const String _kRefreshToken = 'secure_refresh_token';

  /// Luu cap token sau khi dang nhap (goi tu AuthProvider).
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await _secure.write(key: _kAccessToken, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secure.write(key: _kRefreshToken, value: refreshToken);
      }
    } catch (e) {
      debugPrint('SecureTokenStorage.saveTokens error: $e');
    }
  }

  /// Doc access token (null neu chua dang nhap).
  static Future<String?> readAccessToken() async {
    try {
      return await _secure.read(key: _kAccessToken);
    } catch (e) {
      debugPrint('SecureTokenStorage.readAccessToken error: $e');
      return null;
    }
  }

  /// Doc refresh token.
  static Future<String?> readRefreshToken() async {
    try {
      return await _secure.read(key: _kRefreshToken);
    } catch (e) {
      debugPrint('SecureTokenStorage.readRefreshToken error: $e');
      return null;
    }
  }

  /// Xoa TOAN BO token khi logout — tranh token cu sot lai tren may.
  static Future<void> clearTokens() async {
    try {
      await _secure.delete(key: _kAccessToken);
      await _secure.delete(key: _kRefreshToken);
    } catch (e) {
      debugPrint('SecureTokenStorage.clearTokens error: $e');
    }
  }

  // ============================================================
  // SharedPreferences CHI cho cai khong nhay cam (theme, cache UI).
  // ============================================================

  /// Doc theme_mode (khong nhay cam, giu o SharedPreferences).
  static Future<String?> readThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('theme_mode');
    } catch (e) {
      debugPrint('SecureTokenStorage.readThemeMode error: $e');
      return null;
    }
  }

  /// Luu theme_mode.
  static Future<void> saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode);
    } catch (e) {
      debugPrint('SecureTokenStorage.saveThemeMode error: $e');
    }
  }
}
