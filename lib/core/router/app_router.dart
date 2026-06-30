import 'package:flutter/material.dart';

import '../../features/auth/screens/phone_entry_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/bills/screens/bills_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/transfers/screens/transfer_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      AppRoutes.splash => (_) => const SplashScreen(),
      AppRoutes.phoneEntry => (_) => const PhoneEntryScreen(),
      AppRoutes.dashboard => (_) => const DashboardScreen(),
      AppRoutes.transfer => (_) => const TransferScreen(),
      AppRoutes.bills => (_) => const BillsScreen(),
      AppRoutes.history => (_) => const HistoryScreen(),
      _ => (_) => const SplashScreen(),
    };
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
