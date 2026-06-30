import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Holds the single piece of session state the app cares about: which
/// phone number is "logged in". Every other provider that needs the
/// current user reads `phone` from here instead of threading it through
/// constructor params across the widget tree.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.unknown;
  String? phone;

  Future<void> restoreSession() async {
    final savedPhone = await _repository.getSavedPhone();
    phone = savedPhone;
    status = savedPhone == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> signIn(String phoneNumber) async {
    await _repository.savePhone(phoneNumber);
    phone = phoneNumber;
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    phone = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
