import 'package:flutter/material.dart';

import '../../../core/network/result.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../../../models/transaction.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key, required this.state, required this.onRetry});

  final Result<List<Transaction>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      Failure() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                const Text('Impossible de charger les transactions.'),
                TextButton(onPressed: onRetry, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      Success(:final data) when data.isEmpty => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Aucune transaction pour le moment.')),
        ),
      Success(:final data) => Column(
          children: data.map((t) => TransactionTile(transaction: t)).toList(),
        ),
    };
  }
}
