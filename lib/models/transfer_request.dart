/// Body for `POST /api/wallets/transfer`.
class TransferRequest {
  const TransferRequest({
    required this.fromPhone,
    required this.toPhone,
    required this.amount,
    required this.idempotencyKey,
    this.note,
  });

  final String fromPhone;
  final String toPhone;
  final double amount;
  final String idempotencyKey;
  final String? note;

  Map<String, dynamic> toJson() => {
        'fromPhone': fromPhone,
        'toPhone': toPhone,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}

/// Body for `POST /api/wallets/pay-factures`.
class PayFacturesRequest {
  const PayFacturesRequest({
    required this.phone,
    required this.factureIds,
    required this.idempotencyKey,
  });

  final String phone;
  final List<String> factureIds;
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'factureIds': factureIds,
        'idempotencyKey': idempotencyKey,
      };
}
