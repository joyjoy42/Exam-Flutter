import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/result.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/transaction.dart';
import '../../../models/wallet.dart';

/// Owns reads of `/api/wallets/{phone}/balance` and
/// `/api/wallets/{phone}/transactions`, and is reused by the History
/// feature (full list) since it's the same backend resource — duplicating
/// it per-feature would just mean two cache copies going out of sync.
///
/// Read pattern (stale-while-revalidate):
/// 1. Try the network.
/// 2. On success, cache the response and return it.
/// 3. On failure, fall back to whatever is cached (even if stale) so the
///    UI still has something to show offline; only surface an error if
///    there's truly nothing cached.
class WalletRepository {
  WalletRepository(this._api, this._cache);

  final ApiClient _api;
  final CacheService _cache;

  String _balanceKey(String phone) => 'balance::$phone';
  String _transactionsKey(String phone) => 'transactions::$phone';

  Future<Result<Wallet>> getBalance(String phone, {bool forceRefresh = false}) async {
    final key = _balanceKey(phone);
    if (!forceRefresh) {
      final cached = _cache.read(key);
      if (cached != null && !cached.isStale) {
        return Success(Wallet.fromJson(Map<String, dynamic>.from(cached.data as Map)));
      }
    }
    try {
      final json = await _api.get('/api/wallets/$phone/balance') as Map<String, dynamic>;
      await _cache.write(key, json, ttl: AppConstants.cacheTtlBalance);
      return Success(Wallet.fromJson(json));
    } on AppException catch (e) {
      final cached = _cache.read(key);
      if (cached != null) {
        return Success(Wallet.fromJson(Map<String, dynamic>.from(cached.data as Map)), isStale: true);
      }
      return Failure(e);
    }
  }

  Future<Result<List<Transaction>>> getRecentTransactions(
    String phone, {
    int limit = AppConstants.recentTransactionsCount,
    bool forceRefresh = false,
  }) async {
    final result = await _getTransactions(phone, forceRefresh: forceRefresh);
    return switch (result) {
      Success(:final data, :final isStale) => Success(data.take(limit).toList(), isStale: isStale),
      Failure(:final error) => Failure(error),
      Loading() => const Loading(),
    };
  }

  Future<Result<List<Transaction>>> getAllTransactions(
    String phone, {
    bool forceRefresh = false,
  }) {
    return _getTransactions(phone, forceRefresh: forceRefresh);
  }

  Future<Result<List<Transaction>>> _getTransactions(
    String phone, {
    required bool forceRefresh,
  }) async {
    final key = _transactionsKey(phone);
    if (!forceRefresh) {
      final cached = _cache.read(key);
      if (cached != null && !cached.isStale) {
        return Success(_parseTransactions(cached.data, phone));
      }
    }
    try {
      final json = await _api.get('/api/wallets/$phone/transactions');
      await _cache.write(key, json, ttl: AppConstants.cacheTtlTransactions);
      return Success(_parseTransactions(json, phone));
    } on AppException catch (e) {
      final cached = _cache.read(key);
      if (cached != null) {
        return Success(_parseTransactions(cached.data, phone), isStale: true);
      }
      return Failure(e);
    }
  }

  List<Transaction> _parseTransactions(dynamic json, String viewerPhone) {
    final list = (json is List) ? json : (json is Map ? json['items'] as List? ?? [] : []);
    return list
        .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e as Map), viewerPhone: viewerPhone))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Call after a transfer or bill payment succeeds so the dashboard/history
  /// can't show a pre-transaction balance from cache.
  Future<void> invalidate(String phone) => _cache.invalidateForPhone(phone);
}
