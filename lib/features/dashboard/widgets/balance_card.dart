import 'package:flutter/material.dart';

import '../../../core/network/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/wallet.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.state,
    required this.hidden,
    required this.onToggleVisibility,
    required this.onRetry,
  });

  final Result<Wallet> state;
  final bool hidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.seed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 14)),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildAmount(context),
        ],
      ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    return switch (state) {
      Loading() => const SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        ),
      Success(:final data, :final isStale) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              hidden ? '•••••• ${data.currency}' : CurrencyFormatter.format(data.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isStale) ...[
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Tooltip(
                  message: 'Données hors-ligne — dernière valeur connue',
                  child: Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 18),
                ),
              ),
            ],
          ],
        ),
      Failure() => Row(
          children: [
            const Text('Solde indisponible', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
    };
  }
}
