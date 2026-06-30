import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A cached value plus whether it's past its TTL. Repositories return stale
/// entries (rather than null) so the UI can render instantly from disk and
/// optionally label the data as "offline" while a refresh runs in the
/// background — classic stale-while-revalidate.
class CachedEntry<T> {
  const CachedEntry(this.data, this.isStale);

  final T data;
  final bool isStale;
}

/// Lightweight, persistent, TTL-aware key/value cache used to make the
/// dashboard/history/bills screens read instantly on cold start and to
/// keep last-known data available offline.
///
/// Backed by SharedPreferences for v1 simplicity (JSON blobs are small:
/// one balance, a handful of recent transactions). If the app grows to
/// caching large transaction histories or binary data, this is the single
/// place to swap in Hive/Isar/sqflite without touching repositories.
class CacheService {
  CacheService(this._prefs);

  final SharedPreferences _prefs;

  CachedEntry<dynamic>? read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(wrapper['cachedAt'] as String);
      final ttlMs = wrapper['ttlMs'] as int;
      final isStale = DateTime.now().difference(cachedAt).inMilliseconds > ttlMs;
      return CachedEntry<dynamic>(wrapper['data'], isStale);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object? data, {required Duration ttl}) {
    final wrapper = {
      'data': data,
      'cachedAt': DateTime.now().toIso8601String(),
      'ttlMs': ttl.inMilliseconds,
    };
    return _prefs.setString(key, jsonEncode(wrapper));
  }

  Future<void> invalidate(String key) => _prefs.remove(key);

  /// Drops every cache entry tied to a phone number (balance, transactions,
  /// ...). Called right after a transfer or bill payment succeeds so the
  /// next dashboard view is forced to fetch fresh data instead of showing
  /// a pre-transaction balance.
  Future<void> invalidateForPhone(String phone) async {
    final keys = _prefs.getKeys().where((k) => k.endsWith('::$phone'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
