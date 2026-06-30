import '../../../core/network/api_client.dart';
import '../../../core/storage/cache_service.dart';
import '../../../models/transfer_request.dart';

class TransferRepository {
  TransferRepository(this._api, this._cache);

  final ApiClient _api;
  final CacheService _cache;

  Future<void> transfer(TransferRequest request) async {
    await _api.post('/api/wallets/transfer', body: request.toJson());
    // Invalidate both legs of the transfer so neither party's next
    // dashboard view shows a pre-transaction balance from cache.
    await _cache.invalidateForPhone(request.fromPhone);
    await _cache.invalidateForPhone(request.toPhone);
  }
}
