// ============================================================
//  SecureStorageService – MaaCare
//  Encrypted local storage for PII (Personally Identifiable Information)
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  // ✅ AES encryption enabled for secure token storage on Android.
  // resetOnError: true handles Keystore invalidation after factory reset / app reinstall
  // gracefully (re-login required) instead of crashing. Backup is handled via
  // android:fullBackupContent rules excluding FlutterSecureStorage from cloud backup.
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  final _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
