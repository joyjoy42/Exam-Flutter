/// Mirrors one entry of `GET /api/external/factures/{provider}`.
class Facture {
  const Facture({
    required this.id,
    required this.provider,
    required this.reference,
    required this.amount,
    required this.dueDate,
    required this.paid,
  });

  final String id;
  final String provider;
  final String reference;
  final double amount;
  final DateTime? dueDate;
  final bool paid;

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: (json['id'] ?? json['factureId'] ?? '').toString(),
      provider: (json['provider'] ?? '') as String,
      reference: (json['reference'] ?? json['label'] ?? '') as String,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      dueDate: DateTime.tryParse((json['dueDate'] ?? '').toString()),
      paid: (json['paid'] ?? false) as bool,
    );
  }
}
