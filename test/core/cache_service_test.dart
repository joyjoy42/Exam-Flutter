import 'package:badwallet_app/core/storage/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CacheService', () {
    test('returns fresh entry within TTL', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheService(prefs);

      await cache.write('k', {'value': 42}, ttl: const Duration(seconds: 30));
      final entry = cache.read('k');

      expect(entry, isNotNull);
      expect(entry!.isStale, isFalse);
      expect((entry.data as Map)['value'], 42);
    });

    test('marks entry stale once TTL has elapsed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheService(prefs);

      await cache.write('k', {'value': 1}, ttl: const Duration(milliseconds: -1));
      final entry = cache.read('k');

      expect(entry, isNotNull);
      expect(entry!.isStale, isTrue);
    });

    test('invalidateForPhone removes only matching keys', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheService(prefs);

      await cache.write('balance::77000', {'a': 1}, ttl: const Duration(seconds: 30));
      await cache.write('balance::78000', {'b': 2}, ttl: const Duration(seconds: 30));

      await cache.invalidateForPhone('77000');

      expect(cache.read('balance::77000'), isNull);
      expect(cache.read('balance::78000'), isNotNull);
    });
  });
}
