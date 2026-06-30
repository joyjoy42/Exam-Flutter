import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/bills/data/bills_repository.dart';
import 'features/bills/providers/bills_provider.dart';
import 'features/dashboard/data/wallet_repository.dart';
import 'features/dashboard/providers/wallet_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/transfers/data/transfer_repository.dart';
import 'features/transfers/providers/transfer_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  final prefs = await SharedPreferences.getInstance();
  runApp(BadWalletApp(prefs: prefs));
}

/// Composition root: wires the network/storage singletons into
/// repositories, then repositories into the ChangeNotifier providers each
/// feature consumes. Kept in one place so the dependency graph is visible
/// at a glance instead of scattered across feature files.
class BadWalletApp extends StatelessWidget {
  const BadWalletApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final cacheService = CacheService(prefs);
    final secureStorage = SecureStorageService();

    final authRepository = AuthRepository(secureStorage);
    final walletRepository = WalletRepository(apiClient, cacheService);
    final transferRepository = TransferRepository(apiClient, cacheService);
    final billsRepository = BillsRepository(apiClient, cacheService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => WalletProvider(walletRepository)),
        ChangeNotifierProvider(create: (_) => TransferProvider(transferRepository)),
        ChangeNotifierProvider(create: (_) => BillsProvider(billsRepository)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(walletRepository)),
      ],
      child: MaterialApp(
        title: 'BadWallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
