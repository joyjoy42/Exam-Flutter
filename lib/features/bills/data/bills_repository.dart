import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/result.dart';
import '../../../core/storage/cache_service.dart';
import '../../../models/facture.dart';
import '../../../models/transfer_request.dart';

class BillsRepository {
  BillsRepository(this._api, this._cache);

  final ApiClient _api;
  final CacheService _cache;

  String _key(String provider, String phone) => 'factures::$provider::$phone';

  Future<Result<List<Facture>>> getUnpaidFactures(
    String provider,
    String phone, {
    bool forceRefresh = false,
  }) async {
    final key = _key(provider, phone);
    if (!forceRefresh) {
      final cached = _cache.read(key);
      if (cached != null && !cached.isStale) {
        return Success(_parse(cached.data));
      }
    }
    try {
      final json = await _api.get('/api/external/factures/$provider', query: {'phone': phone});
      await _cache.write(key, json, ttl: AppConstants.cacheTtlBills);
      return Success(_parse(json));
    } on AppException catch (e) {
      final cached = _cache.read(key);
      if (cached != null) return Success(_parse(cached.data), isStale: true);
      return Failure(e);
    }
  }

  List<Facture> _parse(dynamic json) {
    final list = (json is List) ? json : (json is Map ? json['items'] as List? ?? [] : []);
    return list
        .map((e) => Facture.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((f) => !f.paid)
        .toList();
  }

  Future<void> payFactures(PayFacturesRequest request) async {
    await _api.post('/api/wallets/pay-factures', body: request.toJson());
    await _cache.invalidateForPhone(request.phone);
  }
}
