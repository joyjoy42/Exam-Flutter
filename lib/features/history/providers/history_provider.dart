import 'package:flutter/foundation.dart';

import '../../../core/network/result.dart';
import '../../../models/transaction.dart';
import '../../dashboard/data/wallet_repository.dart';

/// Reuses [WalletRepository] rather than re-implementing a second client
/// for `/api/wallets/{phone}/transactions` — same endpoint, same cache
/// entry as the dashboard's "recent transactions", just unfiltered.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repository);

  final WalletRepository _repository;

  Result<List<Transaction>> transactionsState = const Loading();

  Future<void> load(String phone, {bool forceRefresh = false}) async {
    transactionsState = const Loading();
    notifyListeners();
    transactionsState = await _repository.getAllTransactions(phone, forceRefresh: forceRefresh);
    notifyListeners();
  }
}
