import 'package:flutter/foundation.dart';

import '../../../core/network/result.dart';
import '../../../models/transaction.dart';
import '../../../models/wallet.dart';
import '../data/wallet_repository.dart';

/// Drives the dashboard: balance + the 5 most recent transactions, each
/// independently in Loading/Success/Failure state so a slow transactions
/// fetch never blocks the balance from rendering (and vice versa).
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._repository);

  final WalletRepository _repository;

  Result<Wallet> balanceState = const Loading();
  Result<List<Transaction>> recentTransactionsState = const Loading();
  bool balanceHidden = false;

  Future<void> load(String phone, {bool forceRefresh = false}) async {
    balanceState = const Loading();
    recentTransactionsState = const Loading();
    notifyListeners();

    final results = await Future.wait([
      _repository.getBalance(phone, forceRefresh: forceRefresh),
      _repository.getRecentTransactions(phone, forceRefresh: forceRefresh),
    ]);

    balanceState = results[0] as Result<Wallet>;
    recentTransactionsState = results[1] as Result<List<Transaction>>;
    notifyListeners();
  }

  Future<void> refresh(String phone) => load(phone, forceRefresh: true);

  void toggleBalanceVisibility() {
    balanceHidden = !balanceHidden;
    notifyListeners();
  }
}
