// core/utils/storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _userNameKey = 'user_name';

  // Token ማስቀመጥ
  Future<void> saveAuthData({
    required String token,
    required int userId,
    required String role,
    required String name,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userRoleKey, value: role);
    await _storage.write(key: _userNameKey, value: name);
  }

  // Token ማምጣት
  Future<String?> getToken() async => await _storage.read(key: _tokenKey);
  Future<String?> getRole() async => await _storage.read(key: _userRoleKey);
  Future<int?> getUserId() async {
    final idStr = await _storage.read(key: _userIdKey);
    return idStr != null ? int.tryParse(idStr) : null;
  }

  // ሎግአውት ሲደረግ መረጃዎችን ማጽዳት
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
