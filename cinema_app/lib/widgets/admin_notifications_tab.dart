import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';

/// Tab "Quản lý thông báo" dành cho Admin.
///
/// Gồm 2 phân đoạn:
/// 1. "Gửi thông báo" — tạo + xem thông báo hệ thống gửi tới người dùng
///    (collection `notifications`).
/// 2. "Báo lỗi người dùng" — inbox nhận báo lỗi phim từ người dùng
///    (collection `error_reports`), cho phép đổi trạng thái
///    pending -> processing -> resolved, ghi chú admin và xoá.
class AdminNotificationsTab extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminNotificationsTab({super.key, this.onDataChanged});

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final TabController _tabController;

  bool _isLoading = true;
  List<_AdminNotificationItem> _notifications = [];

  bool _isLoadingReports = true;
  List<_ErrorReportItem> _reports = [];
  String _reportFilter = 'all'; // all | pending | processing | resolved

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadErrorReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) {
      try {
        return raw.toDate();
      } catch (_) {
        return null;
      }
    }
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  // ================= THÔNG BÁO HỆ THỐNG =================

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

        final createdAt = _parseDate(data['createdAt'] ?? data['created_at']);

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

  // ================= BÁO LỖI NGƯỜI DÙNG =================

  Future<void> _loadErrorReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final snap = await _firestore
          .collection(CollectionNames.errorReports)
          .get();
      final list = <_ErrorReportItem>[];
      for (final doc in snap.docs) {
        list.add(_ErrorReportItem.fromDoc(doc));
      }
      list.sort((a, b) {
        final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dB.compareTo(dA);
      });
      if (!mounted) return;
      setState(() {
        _reports = list;
        _isLoadingReports = false;
      });
    } catch (e) {
      debugPrint('AdminNotificationsTab load reports error: $e');
      if (!mounted) return;
      setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadNotifications(), _loadErrorReports()]);
  }

  int get _pendingCount => _reports
      .where((e) => e.status.toLowerCase() == 'pending')
      .length;

  List<_ErrorReportItem> get _filteredReports {
    if (_reportFilter == 'all') return _reports;
    return _reports
        .where((e) => e.status.toLowerCase() == _reportFilter)
        .toList();
  }

  Future<void> _updateReportStatus(
    _ErrorReportItem item,
    String status, {
    String? adminNote,
  }) async {
    try {
      await _firestore
          .collection(CollectionNames.errorReports)
          .doc(item.docId)
          .update({
        'status': status,
        if (adminNote != null) ...{
          'adminNote': adminNote,
          'admin_note': adminNote,
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển báo lỗi sang: ${_statusLabel(status)}'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadErrorReports();
      widget.onDataChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showReportActionSheet(_ErrorReportItem item) async {
    final noteCtrl = TextEditingController(text: item.adminNote ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.movieTitle.isEmpty
                      ? 'Báo lỗi #${item.docId}'
                      : item.movieTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Người gửi: ${item.userLabel} · ${_formatDate(item.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description.isEmpty
                      ? '(Không có mô tả)'
                      : item.description,
                  style: const TextStyle(fontSize: 13.5, height: 1.45),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú admin (tuỳ chọn)',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _updateReportStatus(
                            item,
                            'processing',
                            adminNote: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                          );
                        },
                        icon: const Icon(Icons.autorenew_rounded, size: 18),
                        label: const Text('Đang xử lý'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _updateReportStatus(
                            item,
                            'resolved',
                            adminNote: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Đã giải quyết'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Xoá báo lỗi?'),
                          content: const Text(
                            'Báo lỗi sẽ bị xoá vĩnh viễn khỏi hệ thống.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Huỷ'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Xoá'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      if (ctx.mounted) Navigator.pop(ctx);
                      try {
                        await _firestore
                            .collection(CollectionNames.errorReports)
                            .doc(item.docId)
                            .delete();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xoá báo lỗi.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _loadErrorReports();
                        widget.onDataChanged?.call();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Xoá thất bại: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Xoá báo lỗi',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    noteCtrl.dispose();
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      default:
        return status;
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
          const SizedBox(height: 12),

          // 2. Tabs: Gửi thông báo | Báo lỗi người dùng (kèm badge pending)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF2B191D) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFFFF3B4E),
              unselectedLabelColor: textSecondary,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                const Tab(text: 'Gửi thông báo'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Báo lỗi người dùng'),
                      if (_pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B4E),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Text(
                            _pendingCount > 99 ? '99+' : '$_pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(
                    isDark, cardBg, textPrimary, textSecondary, borderColor),
                _buildReportsTab(
                    isDark, cardBg, textPrimary, textSecondary, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: GỬI THÔNG BÁO =================

  Widget _buildSendTab(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner hồng "Gửi thông báo đến người dùng"
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

        Text(
          'Danh sách thông báo (${_notifications.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

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
    );
  }

  // ================= TAB 2: BÁO LỖI NGƯỜI DÙNG =================

  Widget _buildReportsTab(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final filters = <Map<String, String>>[
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'pending', 'label': 'Chờ xử lý'},
      {'key': 'processing', 'label': 'Đang xử lý'},
      {'key': 'resolved', 'label': 'Đã xong'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2A1F) : const Color(0xFFEFFDF3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.report_problem_outlined,
                size: 30,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hộp thư báo lỗi ($_pendingCount chờ xử lý)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Bấm vào từng báo lỗi để đổi trạng thái / ghi chú / xoá.',
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
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final selected = _reportFilter == f['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f['label']!),
                  selected: selected,
                  selectedColor: const Color(0xFFFF3B4E),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  backgroundColor:
                      isDark ? const Color(0xFF262626) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: borderColor),
                  ),
                  onSelected: (_) {
                    setState(() => _reportFilter = f['key']!);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingReports
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF3B4E),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF3B4E),
                  onRefresh: _loadErrorReports,
                  child: _filteredReports.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 50),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 44,
                                    color: textSecondary.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Không có báo lỗi nào',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredReports.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildReportCard(
                              item: _filteredReports[index],
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
    );
  }

  Widget _buildReportCard({
    required _ErrorReportItem item,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final status = item.status.toLowerCase();
    final Color statusColor;
    final Color statusBg;
    if (status == 'resolved') {
      statusColor = const Color(0xFF15803D);
      statusBg = const Color(0xFFDCFCE7);
    } else if (status == 'processing') {
      statusColor = const Color(0xFFB45309);
      statusBg = const Color(0xFFFEF3C7);
    } else {
      statusColor = const Color(0xFFFF3B4E);
      statusBg = const Color(0xFFFFECEE);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showReportActionSheet(item),
      child: Container(
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.report_problem_outlined,
                color: Color(0xFFF59E0B),
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.movieTitle.isEmpty
                              ? 'Phim #${item.movieId}'
                              : item.movieTitle,
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
                  Text(
                    item.errorTypeLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B4E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isEmpty
                        ? '(Không có mô tả chi tiết)',
                        : item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Từ: ${item.userLabel}'
                    '${item.episodeLabel.isNotEmpty ? ' · ${item.episodeLabel}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _statusLabel(item.status),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Text(
                        'Bấm để xử lý ›',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        borderRadius:
                            BorderRadius.all(Radius.circular(14)),
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

class _ErrorReportItem {
  final String docId;
  final int movieId;
  final String movieTitle;
  final String userEmail;
  final String userName;
  final int? episodeId;
  final String errorType;
  final String description;
  final String status;
  final String? adminNote;
  final DateTime? createdAt;

  const _ErrorReportItem({
    required this.docId,
    required this.movieId,
    required this.movieTitle,
    required this.userEmail,
    required this.userName,
    required this.episodeId,
    required this.errorType,
    required this.description,
    required this.status,
    required this.adminNote,
    required this.createdAt,
  });

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) {
      try {
        return raw.toDate();
      } catch (_) {
        return null;
      }
    }
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  factory _ErrorReportItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final movieTitle = (data['movieTitle'] ??
            data['movie_title'] ??
            data['movieName'] ??
            '')
        .toString();
    final userEmail =
        (data['userEmail'] ?? data['user_email'] ?? '').toString();
    final userName = (data['userName'] ??
            data['user_name'] ??
            data['username'] ??
            '')
        .toString();
    int? ep;
    final rawEp = data['episodeId'] ?? data['episode_id'];
    if (rawEp is int) {
      ep = rawEp;
    } else if (rawEp is num) {
      ep = rawEp.toInt();
    }
    final currentEp = _parseInt(data['currentEpisode']);
    return _ErrorReportItem(
      docId: doc.id,
      movieId: _parseInt(data['movieId'] ?? data['movie_id']),
      movieTitle: movieTitle,
      userEmail: userEmail,
      userName: userName,
      episodeId: ep ?? (currentEp == 0 ? null : currentEp),
      errorType:
          (data['errorType'] ?? data['error_type'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      adminNote: (data['adminNote'] ?? data['admin_note'])?.toString(),
      createdAt: _parseDate(data['createdAt'] ?? data['created_at']),
    );
  }

  String get errorTypeLabel {
    switch (errorType) {
      case 'video_not_load':
        return 'Video không tải được';
      case 'wrong_episode':
        return 'Sai nội dung / sai tập phim';
      case 'no_sound':
        return 'Không có tiếng';
      case 'lag':
        return 'Giật / lag';
      default:
        return errorType.isEmpty ? 'Báo lỗi phim' : errorType;
    }
  }

  String get userLabel {
    if (userName.isNotEmpty && userEmail.isNotEmpty) {
      return '$userName ($userEmail)';
    }
    if (userEmail.isNotEmpty) return userEmail;
    if (userName.isNotEmpty) return userName;
    return 'Người dùng';
  }

  String get episodeLabel {
    if (episodeId == null) return '';
    return 'Tập $episodeId';
  }
}
