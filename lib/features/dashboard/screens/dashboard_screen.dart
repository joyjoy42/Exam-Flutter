import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final String _phone;

  @override
  void initState() {
    super.initState();
    _phone = context.read<AuthProvider>().phone!;
    // Load once per screen mount; pull-to-refresh / post-transaction
    // invalidation handle subsequent updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().load(_phone);
    });
  }

  Future<void> _openTransfer() async {
    final didTransfer = await Navigator.of(context).pushNamed(AppRoutes.transfer);
    if (didTransfer == true && mounted) {
      unawaited(context.read<WalletProvider>().refresh(_phone));
    }
  }

  Future<void> _openBills() async {
    final didPay = await Navigator.of(context).pushNamed(AppRoutes.bills);
    if (didPay == true && mounted) {
      unawaited(context.read<WalletProvider>().refresh(_phone));
    }
  }

  void _openHistory() {
    Navigator.of(context).pushNamed(AppRoutes.history);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BadWallet'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().signOut();
              if (!mounted) return;
              unawaited(navigator.pushNamedAndRemoveUntil(AppRoutes.phoneEntry, (_) => false));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => wallet.refresh(_phone),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BalanceCard(
              state: wallet.balanceState,
              hidden: wallet.balanceHidden,
              onToggleVisibility: wallet.toggleBalanceVisibility,
              onRetry: () => wallet.refresh(_phone),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: QuickActions(
                  actions: [
                    QuickActionData(
                      icon: Icons.send_rounded,
                      label: 'Transférer',
                      onTap: _openTransfer,
                    ),
                    QuickActionData(
                      icon: Icons.receipt_long_rounded,
                      label: 'Payer',
                      onTap: _openBills,
                    ),
                    QuickActionData(
                      icon: Icons.history_rounded,
                      label: 'Historique',
                      onTap: _openHistory,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transactions récentes', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: _openHistory, child: const Text('Voir tout')),
              ],
            ),
            Card(
              child: RecentTransactionsList(
                state: wallet.recentTransactionsState,
                onRetry: () => wallet.refresh(_phone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
