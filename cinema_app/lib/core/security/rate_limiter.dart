import 'package:flutter/foundation.dart';

/// LOP 6 - CHONG SPAM/CHONG THROTTLE PHIA CLIENT (P2/P3).
///
/// VÌ SAO CAN?
/// - Server NestJS da co @nestjs/throttler (20 req/60s/IP), nhung ke xau
///   van co the bam lien tuc gay lag UI + ton pin/data. Chan ngay tu client
///   bang debounce + gioi han tan suat goi la lop phong thu re nhat.
/// - Dung cho nut "Gui binh luan", "Thich", "Cham diem", "Tim kiem".
///
/// Cach dung:
/// ```dart
/// final limiter = RateLimiter();
/// onPressed: () => limiter.run('send_comment', () => _submit());
/// ```
class RateLimiter {
  /// Map giu thoi diem goi gan nhat cua moi hanh dong (key -> milliseconds).
  final Map<String, int> _lastRun = <String, int>{};

  /// Khoang cach toi thieu giua 2 lan goi (mac dinh 1200ms).
  final int minIntervalMs;

  RateLimiter({this.minIntervalMs = 1200});

  /// Tra ve true neu duoc phep chay (da qua khoang cach), false neu bi chan.
  /// [action] la ham dong bo; neu can async thi await ben trong action.
  bool run(String key, void Function() action, {int? intervalMs}) {
    final wait = intervalMs ?? minIntervalMs;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastRun[key] ?? 0;
    if (now - last < wait) {
      debugPrint('RateLimiter: chan "$key" (bam qua nhanh)');
      return false;
    }
    _lastRun[key] = now;
    action();
    return true;
  }

  /// Xoa lich su 1 key (VD khi chuyen man hinh).
  void reset(String key) => _lastRun.remove(key);

  /// Xoa toan bo lich su.
  void resetAll() => _lastRun.clear();
}

/// Debounce cho o tim kiem: chi goi `action` sau khi user ngung go [delay].
class SearchDebouncer {
  SearchDebouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  int _ticket = 0;

  /// Goi moi lan text doi; chi ticket moi nhat duoc chay.
  void call(Future<void> Function() action) {
    final myTicket = ++_ticket;
    Future.delayed(delay, () async {
      if (myTicket != _ticket) return; // da co ticket moi hon -> bo qua
      try {
        await action();
      } catch (e) {
        debugPrint('SearchDebouncer error: $e');
      }
    });
  }

  /// Huy cac lenh dang cho (VD khi dispose widget).
  void cancel() => _ticket++;
}
