import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/core/security/rate_limiter.dart';

void main() {
  group('RateLimiter (8a/8d)', () {
    test('lan dau cho phep chay', () {
      final limiter = RateLimiter(minIntervalMs: 10000);
      var ran = 0;
      expect(limiter.run('like', () => ran++), isTrue);
      expect(ran, 1);
    });

    test('bam lien tuc bi chan', () {
      final limiter = RateLimiter(minIntervalMs: 10000);
      var ran = 0;
      limiter.run('like', () => ran++);
      expect(limiter.run('like', () => ran++), isFalse);
      expect(ran, 1);
    });

    test('key khac nhau doc lap', () {
      final limiter = RateLimiter(minIntervalMs: 10000);
      var ran = 0;
      limiter.run('like', () => ran++);
      expect(limiter.run('comment', () => ran++), isTrue);
      expect(ran, 2);
    });

    test('reset mo lai key', () {
      final limiter = RateLimiter(minIntervalMs: 10000);
      var ran = 0;
      limiter.run('like', () => ran++);
      limiter.reset('like');
      expect(limiter.run('like', () => ran++), isTrue);
      expect(ran, 2);
    });

    test('resetAll mo lai tat ca', () {
      final limiter = RateLimiter(minIntervalMs: 10000);
      limiter.run('a', () {});
      limiter.run('b', () {});
      limiter.resetAll();
      var ran = 0;
      expect(limiter.run('a', () => ran++), isTrue);
      expect(limiter.run('b', () => ran++), isTrue);
      expect(ran, 2);
    });

    test('intervalMs tuy chinh cho phep chay lai sau khoang cho', () async {
      final limiter = RateLimiter(minIntervalMs: 10000);
      var ran = 0;
      limiter.run('k', () => ran++, intervalMs: 10);
      await Future.delayed(const Duration(milliseconds: 30));
      expect(limiter.run('k', () => ran++, intervalMs: 10), isTrue);
      expect(ran, 2);
    });
  });

  group('SearchDebouncer (8a/8d)', () {
    test('chi ticket moi nhat duoc chay', () async {
      final d = SearchDebouncer(delay: const Duration(milliseconds: 30));
      var ran = 0;
      d.call(() async => ran = 1);
      d.call(() async => ran = 2);
      d.call(() async => ran = 3);
      await Future.delayed(const Duration(milliseconds: 120));
      expect(ran, 3);
    });

    test('cancel huy lenh dang cho', () async {
      final d = SearchDebouncer(delay: const Duration(milliseconds: 30));
      var ran = 0;
      d.call(() async => ran = 99);
      d.cancel();
      await Future.delayed(const Duration(milliseconds: 120));
      expect(ran, 0);
    });

    test('action nem loi khong crash (8a)', () async {
      final d = SearchDebouncer(delay: const Duration(milliseconds: 10));
      d.call(() async => throw Exception('mang loi'));
      await Future.delayed(const Duration(milliseconds: 80));
      // khong throw ra ngoai -> pass
    });
  });
}
