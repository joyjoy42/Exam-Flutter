enum TransactionDirection { incoming, outgoing }

enum TransactionKind { transfer, billPayment, deposit, withdrawal, unknown }

/// Mirrors one entry of `GET /api/wallets/{phone}/transactions`.
///
/// Backend transaction shapes vary across mobile-money style APIs, so
/// parsing is intentionally tolerant: it accepts either an explicit
/// `direction`/`type` field from the server, or falls back to comparing
/// `fromPhone`/`toPhone` against the viewing wallet's phone number.
class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.direction,
    required this.kind,
    required this.counterparty,
    required this.createdAt,
    this.note,
  });

  final String id;
  final double amount;
  final TransactionDirection direction;
  final TransactionKind kind;
  final String counterparty;
  final DateTime createdAt;
  final String? note;

  factory Transaction.fromJson(Map<String, dynamic> json, {required String viewerPhone}) {
    final from = json['fromPhone'] as String?;
    final to = json['toPhone'] as String?;
    final rawType = (json['type'] ?? json['direction'] ?? '').toString().toUpperCase();

    final direction = _resolveDirection(rawType: rawType, from: from, to: to, viewerPhone: viewerPhone);
    final kind = _resolveKind(rawType);
    final counterparty = direction == TransactionDirection.outgoing
        ? (to ?? json['provider'] as String? ?? 'Inconnu')
        : (from ?? json['provider'] as String? ?? 'Inconnu');

    return Transaction(
      id: (json['id'] ?? json['transactionId'] ?? '').toString(),
      amount: ((json['amount'] ?? 0) as num).toDouble().abs(),
      direction: direction,
      kind: kind,
      counterparty: counterparty,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['date'] ?? '').toString()) ??
          DateTime.now(),
      note: json['note'] as String?,
    );
  }

  static TransactionDirection _resolveDirection({
    required String rawType,
    required String? from,
    required String? to,
    required String viewerPhone,
  }) {
    if (rawType.contains('IN') || rawType == 'DEPOSIT' || rawType == 'CREDIT') {
      return TransactionDirection.incoming;
    }
    if (rawType.contains('OUT') ||
        rawType == 'WITHDRAWAL' ||
        rawType == 'DEBIT' ||
        rawType == 'BILL_PAYMENT') {
      return TransactionDirection.outgoing;
    }
    if (from == viewerPhone) return TransactionDirection.outgoing;
    if (to == viewerPhone) return TransactionDirection.incoming;
    return TransactionDirection.outgoing;
  }

  static TransactionKind _resolveKind(String rawType) {
    if (rawType.contains('BILL')) return TransactionKind.billPayment;
    if (rawType.contains('DEPOSIT')) return TransactionKind.deposit;
    if (rawType.contains('WITHDRAW')) return TransactionKind.withdrawal;
    if (rawType.contains('TRANSFER')) return TransactionKind.transfer;
    return TransactionKind.unknown;
  }
}
