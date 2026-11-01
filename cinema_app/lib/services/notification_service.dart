import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import 'api_service.dart';

/// Cài đặt bật/tắt thông báo của người dùng (lưu cục bộ).
class NotificationSettings {
  NotificationSettings._();

  static const String _key = 'notifications_enabled';

  /// true = hiển thị badge/thông báo (mặc định bật).
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_key) ?? true;
    } catch (_) {
      // Giữ mặc định
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {
      // Không lưu được thì chỉ áp dụng trong phiên
    }
  }
}

/// Service gọi API thông báo của người dùng (cần đăng nhập).
class NotificationService {
  NotificationService(this._api);

  final ApiService _api;

  /// GET /notifications — chấp nhận body là mảng hoặc { items | data: [...] }.
  Future<List<AppNotification>> getAll() {
    return _api.get<List<AppNotification>>('/notifications', (raw) {
      final list = raw is List
          ? raw
          : (raw is Map ? (raw['items'] ?? raw['data']) : null);
      if (list is! List) return <AppNotification>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    });
  }

  /// GET /notifications/unread-count — body là số hoặc { count | unreadCount }.
  Future<int> getUnreadCount() {
    return _api.get<int>('/notifications/unread-count', (raw) {
      if (raw is num) return raw.toInt();
      if (raw is Map) {
        final v = raw['count'] ?? raw['unreadCount'] ?? raw['unread'];
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    });
  }

  /// PATCH /notifications/read-all
  Future<void> markAllRead() {
    return _api.patchVoid('/notifications/read-all', {});
  }

  /// PATCH /notifications/:id/read
  Future<void> markRead(int id) {
    return _api.patchVoid('/notifications/$id/read', {});
  }

  /// DELETE /notifications/:id
  Future<void> remove(int id) {
    return _api.delete('/notifications/$id');
  }
}
