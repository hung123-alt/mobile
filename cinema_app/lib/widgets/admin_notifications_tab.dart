import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';

/// Giao diện Tab "Quản lý thông báo" dành cho Admin (theo wireframe).
///
/// Lấy dữ liệu động 100% từ bảng `notifications` trên Firestore và cho phép
/// tạo thông báo mới lưu trực tiếp vào bảng `notifications`.
class AdminNotificationsTab extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminNotificationsTab({super.key, this.onDataChanged});

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<_AdminNotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final snap =
          await _firestore.collection(CollectionNames.notifications).get();
      final list = <_AdminNotificationItem>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final id = _parseInt(data['id'] ?? doc.id, 0);
        final title =
            (data['title'] ?? 'Thông báo hệ thống').toString().trim();
        final rawContent = data['content']?.toString().trim();
        final content = (rawContent != null &&
                rawContent.isNotEmpty &&
                rawContent != 'null')
            ? rawContent
            : 'Thông báo từ hệ thống PhimHay24h.';
        final type = (data['type'] ?? 'update').toString().trim();
        final rawAudience =
            (data['targetAudience'] ?? data['target_audience'])?.toString();
        final targetAudience =
            (rawAudience != null && rawAudience.trim().isNotEmpty)
                ? rawAudience.trim()
                : 'Tất cả người dùng';

        final rawDate =
            (data['createdAt'] ?? data['created_at'] ?? '').toString();
        final createdAt = DateTime.tryParse(rawDate);

        list.add(
          _AdminNotificationItem(
            docId: doc.id,
            id: id,
            title: title,
            content: content,
            type: type,
            targetAudience: targetAudience,
            createdAt: createdAt,
          ),
        );
      }

      list.sort((a, b) {
        final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cmp = dB.compareTo(dA);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });

      if (!mounted) return;
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminNotificationsTab load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
      case 'system':
        return Icons.handyman_outlined;
      case 'event':
      case 'promo':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'update':
      case 'new_movie':
      default:
        return Icons.campaign_outlined;
    }
  }

  /// Hộp thoại "+ Tạo thông báo"
  Future<void> _showCreateNotificationDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedType = 'update';
    String selectedAudience = 'Tất cả người dùng';
    String? errorMsg;
    bool isSubmitting = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Tạo thông báo mới',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề thông báo *',
                        hintText: 'VD: Cập nhật phim mới tuần này',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Nội dung thông báo *',
                        hintText: 'Nhập nội dung chi tiết...',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Loại thông báo',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'update',
                          child: Row(
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 18,
                                color: Color(0xFFE11D48),
                              ),
                              SizedBox(width: 8),
                              Text('Cập nhật phim mới'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Row(
                            children: [
                              Icon(
                                Icons.handyman_outlined,
                                size: 18,
                                color: Color(0xFFE11D48),
                              ),
                              SizedBox(width: 8),
                              Text('Bảo trì hệ thống'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'event',
                          child: Row(
                            children: [
                              Icon(
                                Icons.card_giftcard_rounded,
                                size: 18,
                                color: Color(0xFFE11D48),
                              ),
                              SizedBox(width: 8),
                              Text('Sự kiện / Quà tặng'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAudience,
                      decoration: InputDecoration(
                        labelText: 'Đối tượng nhận',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tất cả người dùng',
                          child: Text('Tất cả người dùng'),
                        ),
                        DropdownMenuItem(
                          value: 'Người dùng đang hoạt động',
                          child: Text('Người dùng đang hoạt động'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedAudience = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final content = contentCtrl.text.trim();

                          if (title.isEmpty) {
                            setDialogState(() {
                              errorMsg = 'Vui lòng nhập tiêu đề thông báo';
                            });
                            return;
                          }
                          if (content.isEmpty) {
                            setDialogState(() {
                              errorMsg = 'Vui lòng nhập nội dung thông báo';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMsg = null;
                          });

                          try {
                            int maxId = 0;
                            for (final n in _notifications) {
                              if (n.id > maxId) maxId = n.id;
                            }
                            final nextId = maxId + 1;
                            final nowIso = DateTime.now().toIso8601String();

                            await _firestore
                                .collection(CollectionNames.notifications)
                                .doc(nextId.toString())
                                .set({
                              'id': nextId,
                              'title': title,
                              'content': content,
                              'type': selectedType,
                              'targetAudience': selectedAudience,
                              'target_audience': selectedAudience,
                              'status': 'sent',
                              'isRead': false,
                              'is_read': 0,
                              'linkUrl': null,
                              'link_url': null,
                              'createdAt': nowIso,
                              'created_at': nowIso,
                            });

                            if (ctx.mounted) {
                              Navigator.pop(ctx, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMsg = 'Gửi thông báo thất bại: $e';
                            });
                          }
                        },
                  icon: const Icon(Icons.send_rounded, size: 17),
                  label: Text(isSubmitting ? 'Đang gửi...' : 'Gửi thông báo'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã tạo và gửi thông báo thành công!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadNotifications();
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề "Quản lý thông báo" + Nút "+ Tạo thông báo"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý thông báo',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _showCreateNotificationDialog,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Tạo thông báo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Banner hồng "Gửi thông báo đến người dùng"
          GestureDetector(
            onTap: _showCreateNotificationDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2B191D) : const Color(0xFFFFECEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 32,
                    color: Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gửi thông báo đến người dùng',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Thông báo bảo trì, cập nhật phim mới, sự kiện,...',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Tiêu đề "Danh sách thông báo (X)"
          Text(
            'Danh sách thông báo (${_notifications.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Danh sách các thẻ thông báo
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF3B4E),
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFF3B4E),
                    onRefresh: _loadNotifications,
                    child: _notifications.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 50),
                              Center(
                                child: Text(
                                  'Chưa có thông báo nào trong hệ thống',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _buildNotificationCard(
                                item: _notifications[index],
                                isDark: isDark,
                                cardBg: cardBg,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                borderColor: borderColor,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required _AdminNotificationItem item,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bên trái trong khung vuông bo góc màu hồng nhạt
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF2B191D) : const Color(0xFFFFECEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForType(item.type),
              color: const Color(0xFFE11D48),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),

          // Nội dung thông báo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng trên: Tiêu đề + Ngày gửi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Mô tả / Nội dung thông báo
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                // Hàng dưới: Đối tượng nhận + Nhãn "Đã gửi"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge đối tượng nhận
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sell_outlined,
                            size: 13,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.targetAudience,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge "Đã gửi"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Đã gửi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNotificationItem {
  final String docId;
  final int id;
  final String title;
  final String content;
  final String type;
  final String targetAudience;
  final DateTime? createdAt;

  const _AdminNotificationItem({
    required this.docId,
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.targetAudience,
    required this.createdAt,
  });
}

