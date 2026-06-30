import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Restores the saved session (if any) and routes to the dashboard or the
/// phone-entry screen. The artificial minimum delay keeps the BadWallet
/// logo on screen long enough to read even when the secure-storage read
/// resolves instantly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    final minimumDelay = Future.delayed(const Duration(milliseconds: 900));
    await Future.wait([auth.restoreSession(), minimumDelay]);
    if (!mounted) return;

    final route = auth.status == AuthStatus.signedIn ? AppRoutes.dashboard : AppRoutes.phoneEntry;
    unawaited(Navigator.of(context).pushReplacementNamed(route));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.seed,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  size: 52, color: AppColors.seed),
            ),
            const SizedBox(height: 20),
            const Text(
              'BadWallet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
