import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/collection_names.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'navigation_shell.dart';

/// Thanh Navbar trên cùng dùng chung toàn ứng dụng (HomePage, SearchPage, CategoryPage, FavoritePage, ProfilePage...).
///
/// Hỗ trợ đặt trực tiếp trong `Column` hoặc gán vào `Scaffold.appBar` nhờ [PreferredSizeWidget].
/// - Logo `PhimHay24h` nằm chính giữa, chữ "24h" phủ gradient đỏ-cam.
/// - Không có Hamburger icon bên trái (chỉ hiện nút Back nếu trang được push lên và [showBackIfCanPop] = true, hoặc truyền [leading] tuỳ chỉnh).
/// - Bấm vào logo mặc định sẽ quay về tab Trang chủ.
/// - Bên phải gồm icon Chuông thông báo (nhận thông báo thời gian thực từ Firestore) và nút chuyển đổi Sáng / Tối.
class AppTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackIfCanPop;
  final VoidCallback? onLogoTap;
  final Widget? leading;
  final Widget? trailing;

  const AppTopNavbar({
    super.key,
    this.showBackIfCanPop = false,
    this.onLogoTap,
    this.leading,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = showBackIfCanPop && Navigator.canPop(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Widget bên trái (ưu tiên leading tuỳ chỉnh, hoặc nút Back nếu trang được push)
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: leading!,
              )
            else if (canPop)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

            // Logo PhimHay24h căn chính giữa
            GestureDetector(
              onTap: onLogoTap ?? () => NavigationShell.goHome(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'PhimHay',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0B1021),
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF1E27), Color(0xFFFF6A00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: const Text(
                            '24h',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Widget bên phải: Icon Chuông thông báo + Nút Sáng / Tối
            Align(
              alignment: Alignment.centerRight,
              child: trailing ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _UserNotificationBellButton(),
                      ListenableBuilder(
                        listenable: ThemeProvider.instance,
                        builder: (context, _) {
                          final isDarkMode = ThemeProvider.instance.isDarkMode;
                          return IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              isDarkMode
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              color: isDark
                                  ? Colors.amber
                                  : const Color(0xFF374151),
                              size: 22,
                            ),
                            onPressed: () =>
                                ThemeProvider.instance.toggleTheme(),
                          );
                        },
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút Chuông thông báo ở giao diện người dùng (lắng nghe realtime từ Firestore `notifications`)
class _UserNotificationBellButton extends StatefulWidget {
  const _UserNotificationBellButton();

  @override
  State<_UserNotificationBellButton> createState() =>
      _UserNotificationBellButtonState();
}

class _UserNotificationBellButtonState
    extends State<_UserNotificationBellButton> {
  static const String _prefsReadKey = 'user_read_notification_doc_ids';
  static final ValueNotifier<Set<String>> _readDocIdsNotifier =
      ValueNotifier<Set<String>>({});
  static bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _ensureReadIdsLoaded();
  }

  Future<void> _ensureReadIdsLoaded() async {
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsReadKey) ?? [];
      _readDocIdsNotifier.value = saved.toSet();
    } catch (_) {}
  }

  Future<void> _markAllAsRead(List<String> docIds) async {
    final updated = {..._readDocIdsNotifier.value, ...docIds};
    _readDocIdsNotifier.value = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsReadKey, updated.toList());
    } catch (_) {}
  }

  Future<void> _markOneAsRead(String docId) async {
    if (_readDocIdsNotifier.value.contains(docId)) return;
    final updated = {..._readDocIdsNotifier.value, docId};
    _readDocIdsNotifier.value = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsReadKey, updated.toList());
    } catch (_) {}
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  List<_UserNotificationItem> _parseNotifications(
    QuerySnapshot<Map<String, dynamic>>? snap,
  ) {
    if (snap == null) return [];
    final currentUser = AuthProvider.instance.currentUser;
    final isAuthenticated = currentUser != null;
    final list = <_UserNotificationItem>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final targetAudience =
          (data['targetAudience'] ?? data['target_audience'] ?? '')
              .toString()
              .trim();
      final targetUserId = _parseInt(data['user_id'] ?? data['userId'], 0);

      // Nếu thông báo chỉ gửi cho "Người dùng đang hoạt động" thì khách chưa đăng nhập không nhận
      if (targetAudience == 'Người dùng đang hoạt động' && !isAuthenticated) {
        continue;
      }

      // Nếu thông báo gắn riêng cho 1 user_id cụ thể (và không có targetAudience chung)
      if (targetAudience.isEmpty &&
          targetUserId > 0 &&
          currentUser != null &&
          targetUserId != currentUser.id) {
        continue;
      }

      final id = _parseInt(data['id'] ?? doc.id, 0);
      final title = (data['title'] ?? 'Thông báo').toString().trim();
      final rawContent = data['content']?.toString().trim();
      final content = (rawContent != null &&
              rawContent.isNotEmpty &&
              rawContent != 'null')
          ? rawContent
          : 'Thông báo từ hệ thống PhimHay24h.';
      final type = (data['type'] ?? 'update').toString().trim();
      final rawDate =
          (data['createdAt'] ?? data['created_at'] ?? '').toString();
      final createdAt = DateTime.tryParse(rawDate);

      list.add(
        _UserNotificationItem(
          docId: doc.id,
          id: id,
          title: title,
          content: content,
          type: type,
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

    return list;
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Mới đây';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _openNotificationsSheet(
    BuildContext context,
    List<_UserNotificationItem> items,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: _readDocIdsNotifier,
              builder: (context, readIds, _) {
                final unreadCount =
                    items.where((e) => !readIds.contains(e.docId)).length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thanh kéo trên cùng
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.notifications_active_outlined,
                                color: Color(0xFFFF3B4E),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Thông báo (${items.length})',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (unreadCount > 0)
                            TextButton(
                              onPressed: () {
                                _markAllAsRead(
                                  items.map((e) => e.docId).toList(),
                                );
                              },
                              child: const Text(
                                'Đánh dấu đã đọc',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF3B4E),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: borderColor),

                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 44,
                              color: textSecondary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Hiện chưa có thông báo nào',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                       Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isUnread = !readIds.contains(item.docId);

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _markOneAsRead(item.docId),
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? (isDark
                                          ? const Color(0xFF2B191D)
                                          : const Color(0xFFFFF5F6))
                                      : (isDark
                                          ? const Color(0xFF262626)
                                          : const Color(0xFFF9FAFB)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isUnread
                                        ? const Color(0xFFFF3B4E)
                                            .withValues(alpha: 0.35)
                                        : borderColor,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3B4E)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getIconForType(item.type),
                                        color: const Color(0xFFE11D48),
                                        size: 21,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(
                                                    left: 6,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFFFF3B4E),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.content,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatDate(item.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSecondary.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(CollectionNames.notifications)
          .snapshots(),
      builder: (context, snapshot) {
        final items = _parseNotifications(snapshot.data);

        return ValueListenableBuilder<Set<String>>(
          valueListenable: _readDocIdsNotifier,
          builder: (context, readIds, _) {
            final unreadCount =
                items.where((e) => !readIds.contains(e.docId)).length;

            return IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Thông báo',
              onPressed: () => _openNotificationsSheet(context, items),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    unreadCount > 0
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_rounded,
                    color: isDark ? Colors.white : const Color(0xFF374151),
                    size: 22,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B4E),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _UserNotificationItem {
  final String docId;
  final int id;
  final String title;
  final String content;
  final String type;
  final DateTime? createdAt;

  const _UserNotificationItem({
    required this.docId,
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
  });
}
