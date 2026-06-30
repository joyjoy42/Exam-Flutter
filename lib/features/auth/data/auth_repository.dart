import '../../../core/storage/secure_storage_service.dart';

/// "Authentication" here is simulated per the spec: the phone number is the
/// API identifier, persisted locally so the app can skip straight to the
/// dashboard on relaunch. A real auth upgrade (OTP/PIN/biometric session
/// token) plugs in at this seam without the rest of the app changing.
class AuthRepository {
  AuthRepository(this._secureStorage);

  final SecureStorageService _secureStorage;

  Future<String?> getSavedPhone() => _secureStorage.readPhone();

  Future<void> savePhone(String phone) => _secureStorage.savePhone(phone);

  Future<void> signOut() => _secureStorage.clear();
}
