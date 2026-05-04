import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _sessionTokenKey = 'session_token';
  static const _userIdKey = 'user_id';

  // Session Token
  Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _sessionTokenKey, value: token);
  }

  Future<String?> getSessionToken() async {
    return _storage.read(key: _sessionTokenKey);
  }

  Future<void> deleteSessionToken() async {
    await _storage.delete(key: _sessionTokenKey);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Check if logged in
  Future<bool> hasSession() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }
}
