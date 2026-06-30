import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Shared between the dashboard's "5 dernières transactions" and the full
/// History screen — one rendering rule for the red/green color coding
/// keeps the two screens visually consistent.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = transaction.direction == TransactionDirection.outgoing;
    final color = isOutgoing ? AppColors.danger : AppColors.success;
    final sign = isOutgoing ? '-' : '+';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          isOutgoing ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
        ),
      ),
      title: Text(
        _kindLabel(transaction),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${transaction.counterparty} · ${DateFormat('dd MMM, HH:mm', 'fr_FR').format(transaction.createdAt)}',
      ),
      trailing: Text(
        '$sign${CurrencyFormatter.format(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _kindLabel(Transaction t) {
    switch (t.kind) {
      case TransactionKind.billPayment:
        return 'Paiement de facture';
      case TransactionKind.deposit:
        return 'Dépôt';
      case TransactionKind.withdrawal:
        return 'Retrait';
      case TransactionKind.transfer:
        return t.direction == TransactionDirection.outgoing ? 'Transfert envoyé' : 'Transfert reçu';
      case TransactionKind.unknown:
        return 'Transaction';
    }
  }
}
