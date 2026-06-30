import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Keystore/Keychain-backed storage for the one piece of identity this
/// "simulated auth" app keeps: the user's phone number. Never put balances
/// or transactions here — that's cache data, not secrets, and belongs in
/// [CacheService].
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readPhone() => _storage.read(key: AppConstants.secureStoragePhoneKey);

  Future<void> savePhone(String phone) =>
      _storage.write(key: AppConstants.secureStoragePhoneKey, value: phone);

  Future<void> clear() => _storage.delete(key: AppConstants.secureStoragePhoneKey);
}
