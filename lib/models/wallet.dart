/// Mirrors the response of `GET /api/wallets/{phone}/balance`.
class Wallet {
  const Wallet({required this.phone, required this.balance, required this.currency});

  final String phone;
  final double balance;
  final String currency;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      phone: (json['phone'] ?? json['walletPhone'] ?? '') as String,
      balance: ((json['balance'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'XOF') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'balance': balance,
        'currency': currency,
      };
}
