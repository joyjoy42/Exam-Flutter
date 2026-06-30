import 'package:badwallet_app/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction.fromJson', () {
    test('resolves outgoing direction when viewer is the sender', () {
      final tx = Transaction.fromJson({
        'id': 't1',
        'amount': 5000,
        'fromPhone': '770000000',
        'toPhone': '780000000',
        'createdAt': '2026-01-01T10:00:00Z',
      }, viewerPhone: '770000000');

      expect(tx.direction, TransactionDirection.outgoing);
      expect(tx.counterparty, '780000000');
    });

    test('resolves incoming direction when viewer is the recipient', () {
      final tx = Transaction.fromJson({
        'id': 't2',
        'amount': 1200,
        'fromPhone': '780000000',
        'toPhone': '770000000',
        'createdAt': '2026-01-01T10:00:00Z',
      }, viewerPhone: '770000000');

      expect(tx.direction, TransactionDirection.incoming);
      expect(tx.counterparty, '780000000');
    });

    test('honors an explicit type field over phone comparison', () {
      final tx = Transaction.fromJson({
        'id': 't3',
        'amount': 2000,
        'type': 'BILL_PAYMENT',
        'provider': 'SENELEC',
        'createdAt': '2026-01-01T10:00:00Z',
      }, viewerPhone: '770000000');

      expect(tx.direction, TransactionDirection.outgoing);
      expect(tx.kind, TransactionKind.billPayment);
      expect(tx.counterparty, 'SENELEC');
    });
  });
}
