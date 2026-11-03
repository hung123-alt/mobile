import 'package:flutter_test/flutter_test.dart';

/// Mô hình Thông báo (NotificationItem) và Dịch vụ quản lý thông báo
/// phục vụ kiểm thử đơn vị cho Nhóm 4 – Thông báo (US24 - US25).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String recipientUserId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      recipientUserId: recipientUserId,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService {
  final List<NotificationItem> _notifications = [];

  void seed(List<NotificationItem> items) {
    _notifications
      ..clear()
      ..addAll(items);
  }

  /// US24: Chỉ hiển thị các thông báo thuộc tài khoản hiện tại
  List<NotificationItem> getNotificationsForUser(String currentUserId) {
    final list = _notifications
        .where((n) => n.recipientUserId == currentUserId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// US25: Đánh dấu thông báo được chọn sang trạng thái đã đọc
  ({NotificationItem? item, String? error}) markAsRead({
    required String currentUserId,
    required String notificationId,
  }) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      return (item: null, error: 'Không tìm thấy thông báo');
    }

    final target = _notifications[index];
    if (target.recipientUserId != currentUserId) {
      return (
        item: null,
        error: 'Không có quyền cập nhật thông báo của tài khoản khác',
      );
    }

    final updated = target.copyWith(isRead: true);
    _notifications[index] = updated;
    return (item: updated, error: null);
  }
}

void main() {
  late NotificationService notificationService;

  setUp(() {
    notificationService = NotificationService();
    notificationService.seed([
      NotificationItem(
        id: 'noti_1',
        recipientUserId: 'user_A',
        title: 'Tập mới ra mắt',
        body: 'Bộ phim bạn yêu thích vừa cập nhật Tập 10.',
        createdAt: DateTime(2026, 3, 1, 9, 0),
        isRead: false,
      ),
      NotificationItem(
        id: 'noti_2',
        recipientUserId: 'user_A',
        title: 'Phản hồi bình luận',
        body: 'Có người vừa trả lời bình luận của bạn.',
        createdAt: DateTime(2026, 3, 2, 14, 0),
        isRead: false,
      ),
      NotificationItem(
        id: 'noti_3',
        recipientUserId: 'user_B',
        title: 'Thông báo riêng của User B',
        body: 'Mật khẩu của bạn vừa được thay đổi.',
        createdAt: DateTime(2026, 3, 2, 16, 0),
        isRead: false,
      ),
    ]);
  });

  group('Nhóm 4 – Thông báo (US24 - US25)', () {
    // =========================================================================
    // US24: Là người dùng, tôi muốn xem các thông báo gửi đến mình để cập nhật thông tin
    // Tiêu chí: Chỉ hiển thị thông báo thuộc tài khoản hiện tại.
    // =========================================================================
    group('US24 - Xem danh sách thông báo của tài khoản hiện tại', () {
      test('Chỉ hiển thị thông báo gửi tới user_A và không lộ thông báo của user_B', () {
        final userANotifications = notificationService.getNotificationsForUser(
          'user_A',
        );

        expect(userANotifications.length, 2);
        expect(
          userANotifications.every((n) => n.recipientUserId == 'user_A'),
          isTrue,
        );
        expect(userANotifications.first.id, 'noti_2'); // Mới nhất lên đầu
        expect(
          userANotifications.any((n) => n.id == 'noti_3'),
          isFalse,
        );
      });

      test('Trả về danh sách rỗng nếu tài khoản chưa có thông báo nào', () {
        final emptyList = notificationService.getNotificationsForUser(
          'user_no_noti',
        );
        expect(emptyList, isEmpty);
      });
    });

    // =========================================================================
    // US25: Là người dùng, tôi muốn đánh dấu thông báo đã đọc để theo dõi thông tin mới
    // Tiêu chí: Thông báo được chọn chuyển sang trạng thái đã đọc.
    // =========================================================================
    group('US25 - Đánh dấu thông báo đã đọc', () {
      test('Chuyển trạng thái thông báo được chọn sang đã đọc (isRead == true)', () {
        final beforeList = notificationService.getNotificationsForUser('user_A');
        final unreadTarget = beforeList.firstWhere((n) => n.id == 'noti_1');
        expect(unreadTarget.isRead, isFalse);

        final res = notificationService.markAsRead(
          currentUserId: 'user_A',
          notificationId: 'noti_1',
        );

        expect(res.error, isNull);
        expect(res.item, isNotNull);
        expect(res.item!.isRead, isTrue);

        // Kiểm tra thông báo còn lại của user_A vẫn giữ nguyên trạng thái chưa đọc
        final afterList = notificationService.getNotificationsForUser('user_A');
        final noti2 = afterList.firstWhere((n) => n.id == 'noti_2');
        expect(noti2.isRead, isFalse);
      });

      test('Từ chối đánh dấu đã đọc đối với thông báo thuộc tài khoản khác', () {
        final res = notificationService.markAsRead(
          currentUserId: 'user_A',
          notificationId: 'noti_3', // Thuộc user_B
        );

        expect(res.item, isNull);
        expect(
          res.error,
          'Không có quyền cập nhật thông báo của tài khoản khác',
        );
      });
    });
  });
}

