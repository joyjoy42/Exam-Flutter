import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for environment + tuning constants. Resolving the backend
/// host here (instead of scattering `localhost` strings through the app)
/// is what lets the same build target an emulator, a physical device on the
/// LAN, or a staging/production API via `--dart-define=API_BASE_URL=...`.
class AppConstants {
  AppConstants._();

  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:8080';
    // The Android emulator routes 10.0.2.2 to the host machine's localhost.
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static const Duration requestTimeout = Duration(seconds: 15);
  static const int maxGetRetries = 2;

  // Cache TTLs — short for balance (money must look fresh), longer for
  // bills which change at most a few times a month.
  static const Duration cacheTtlBalance = Duration(seconds: 30);
  static const Duration cacheTtlTransactions = Duration(seconds: 60);
  static const Duration cacheTtlBills = Duration(minutes: 5);

  static const int recentTransactionsCount = 5;

  static const List<String> billProviders = [
    'ISM',
    'WOYAFAL',
    'RAPIDO',
    'SENELEC',
  ];

  static const String currencyCode = 'XOF';

  static const String secureStoragePhoneKey = 'user_phone';
}
