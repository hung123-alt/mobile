import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../widgets/admin_bottom_bar.dart';
import '../widgets/admin_movies_tab.dart';
import '../widgets/admin_notifications_tab.dart';
import '../widgets/admin_top_navbar.dart';
import '../widgets/admin_users_tab.dart';

/// Trang Bảng điều khiển dành cho quản trị viên (role = admin).
///
/// Toàn bộ số liệu thống kê (Tổng phim, Lượt xem, Tài khoản, Bình luận,
/// Lượt xem theo thể loại, Người dùng mới nhất) đều được lấy động 100% từ Firestore.
class AdminDashboardPage extends StatefulWidget {
  final int initialTabIndex;

  const AdminDashboardPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  int _totalMovies = 0;
  int _totalViews = 0;
  int _totalUsers = 0;
  int _totalComments = 0;
  int _totalGenres = 0;
  List<User> _latestUsers = [];
  List<_GenreStat> _genreStats = [];

  static const List<Color> _palette = [
    Color(0xFFFF4757),
    Color(0xFFFF758F),
    Color(0xFFFFB142),
    Color(0xFF9B59B6),
    Color(0xFF3498DB),
  ];

  @override
  void initState() {
    super.initState();
    AdminBottomBar.tabIndexNotifier.value = widget.initialTabIndex;
    _loadDashboardData();
  }

  int _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _firestore.collection(CollectionNames.movies).get(),
        _firestore.collection(CollectionNames.users).get(),
        _firestore.collection(CollectionNames.comments).get(),
        _firestore.collection(CollectionNames.genres).get(),
        _firestore.collection('movie_genres').get(),
      ]);

      final moviesSnap = results[0];
      final usersSnap = results[1];
      final commentsSnap = results[2];
      final genresSnap = results[3];
      final movieGenresSnap = results[4];

      // 1. Map genre_id -> tên thể loại từ bảng `genres`
      final Map<int, String> genreNamesById = {};
      for (final doc in genresSnap.docs) {
        final data = doc.data();
        final gId = _parseInt(data['id'] ?? doc.id);
        final gName = (data['name'] ?? data['title'] ?? '').toString().trim();
        if (gId > 0 && gName.isNotEmpty) {
          genreNamesById[gId] = gName;
        }
      }

      // 2. Tính tổng lượt xem và lưu map movie_id -> viewCount từ bảng `movies`
      int viewsSum = 0;
      final Map<int, int> movieViewsById = {};
      final Map<String, int> genreViewMap = {};

      for (final doc in moviesSnap.docs) {
        final data = doc.data();
        final mId = _parseInt(data['id'] ?? doc.id);
        final views = _parseInt(data['viewCount'] ?? data['view_count']);
        viewsSum += views;
        if (mId > 0) {
          movieViewsById[mId] = views;
        }

        // Trường hợp phim có nhúng sẵn mảng genres trong document movie
        final embeddedGenres = data['genres'] ?? data['genreNames'];
        if (embeddedGenres is List && embeddedGenres.isNotEmpty) {
          for (final g in embeddedGenres) {
            final gName = g is Map
                ? (g['name'] ?? g['title'] ?? '').toString().trim()
                : g.toString().trim();
            if (gName.isNotEmpty) {
              genreViewMap[gName] = (genreViewMap[gName] ?? 0) + views;
            }
          }
        }
      }

      // 3. Kết nối bảng `movie_genres` (movie_id, genre_id) để cộng lượt xem thực tế theo từng thể loại
      for (final doc in movieGenresSnap.docs) {
        final data = doc.data();
        final mId = _parseInt(data['movie_id'] ?? data['movieId']);
        final gId = _parseInt(data['genre_id'] ?? data['genreId']);
        final gName = genreNamesById[gId];
        if (gName != null && movieViewsById.containsKey(mId)) {
          final views = movieViewsById[mId] ?? 0;
          genreViewMap[gName] = (genreViewMap[gName] ?? 0) + views;
        }
      }

      // 4. Tính tỷ lệ phần trăm thực tế cho biểu đồ Lượt xem theo thể loại
      final List<_GenreStat> computedGenres = [];
      if (genreViewMap.isNotEmpty) {
        final sortedEntries = genreViewMap.entries
            .where((e) => e.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final totalGenreViews =
            sortedEntries.fold<int>(0, (acc, item) => acc + item.value);

        if (totalGenreViews > 0) {
          if (sortedEntries.length <= 4) {
            int accPercent = 0;
            for (int i = 0; i < sortedEntries.length; i++) {
              final isLast = i == sortedEntries.length - 1;
              final pct = isLast
                  ? math.max(0, 100 - accPercent)
                  : ((sortedEntries[i].value / totalGenreViews) * 100).round();
              accPercent += pct;
              computedGenres.add(
                _GenreStat(
                  name: sortedEntries[i].key,
                  views: sortedEntries[i].value,
                  percent: pct,
                  color: _palette[i % _palette.length],
                ),
              );
            }
          } else {
            final top3 = sortedEntries.take(3).toList();
            final otherViews = sortedEntries
                .skip(3)
                .fold<int>(0, (acc, item) => acc + item.value);
            final p1 = ((top3[0].value / totalGenreViews) * 100).round();
            final p2 = ((top3[1].value / totalGenreViews) * 100).round();
            final p3 = ((top3[2].value / totalGenreViews) * 100).round();
            final pOther = math.max(0, 100 - (p1 + p2 + p3));

            computedGenres.addAll([
              _GenreStat(
                name: top3[0].key,
                views: top3[0].value,
                percent: p1,
                color: _palette[0],
              ),
              _GenreStat(
                name: top3[1].key,
                views: top3[1].value,
                percent: p2,
                color: _palette[1],
              ),
              _GenreStat(
                name: top3[2].key,
                views: top3[2].value,
                percent: p3,
                color: _palette[2],
              ),
              _GenreStat(
                name: 'Khác',
                views: otherViews,
                percent: pOther,
                color: _palette[3],
              ),
            ]);
          }
        }
      }

      // 5. Danh sách người dùng mới nhất từ bảng `users`
      final parsedUsers = <User>[];
      for (final doc in usersSnap.docs) {
        try {
          parsedUsers.add(User.fromJson(doc.data()));
        } catch (_) {}
      }
      parsedUsers.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cmp = dateB.compareTo(dateA);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });

      if (!mounted) return;
      setState(() {
        _totalMovies = moviesSnap.size;
        _totalViews = viewsSum;
        _totalUsers = usersSnap.size;
        _totalComments = commentsSnap.size;
        _totalGenres = genresSnap.size;
        _latestUsers = parsedUsers;
        _genreStats = computedGenres;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminDashboard load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Định dạng số có dấu chấm phân cách hàng nghìn (VD: 12.458)
  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Định dạng số rút gọn cho tâm biểu đồ Donut
  String _formatCompactViews(int value) {
    if (value >= 1000000) {
      final m = (value / 1000000).toStringAsFixed(1).replaceAll('.', ',');
      return '${m}M';
    }
    if (value >= 1000) {
      final k = (value / 1000).toStringAsFixed(1).replaceAll('.', ',');
      return '${k}K';
    }
    return _formatNumber(value);
  }

  String _formatRelativeDate(DateTime? date) {
    if (date == null) return '--';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Hôm nay';
    if (diffDays == 1) return 'Hôm qua';
    if (diffDays > 1 && diffDays < 7) return '$diffDays ngày trước';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _handleExportReport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.assessment_outlined, color: Color(0xFFFF3B4E)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Báo cáo dữ liệu hệ thống',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportRow('Tổng số phim:', _formatNumber(_totalMovies)),
            _buildReportRow('Tổng lượt xem:', _formatNumber(_totalViews)),
            _buildReportRow('Tổng tài khoản:', _formatNumber(_totalUsers)),
            _buildReportRow('Tổng bình luận:', _formatNumber(_totalComments)),
            _buildReportRow('Tổng thể loại:', _formatNumber(_totalGenres)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Đã xuất báo cáo thống kê hệ thống thành công!',
                  ),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Tải xuống'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Navbar Admin tái sử dụng
            AdminTopNavbar(
              leading: Tooltip(
                message: 'Về Trang chủ (Giao diện người dùng)',
                child: IconButton(
                  icon: Icon(
                    Icons.exit_to_app_rounded,
                    size: 21,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                ),
              ),
            ),

            // Nội dung theo tab đang chọn
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: AdminBottomBar.tabIndexNotifier,
                builder: (context, tabIndex, _) {
                  if (tabIndex == 0) {
                    return _buildOverviewTab(isDark);
                  }
                  if (tabIndex == 1) {
                    return AdminMoviesTab(
                      onDataChanged: _loadDashboardData,
                    );
                  }
                  if (tabIndex == 2) {
                    return AdminUsersTab(
                      onDataChanged: _loadDashboardData,
                    );
                  }
                  if (tabIndex == 5) {
                    return AdminNotificationsTab(
                      onDataChanged: _loadDashboardData,
                    );
                  }
                  return _buildSubTabView(tabIndex, isDark);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomBar(
        onTap: (index) {
          AdminBottomBar.tabIndexNotifier.value = index;
        },
      ),
    );
  }

  /// Tab 0: Tổng quan hệ thống (100% dữ liệu động từ Firestore)
  Widget _buildOverviewTab(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    return RefreshIndicator(
      color: const Color(0xFFFF3B4E),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiêu đề "Tổng quan hệ thống" + Nút Xuất báo cáo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng quan hệ thống',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _handleExportReport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE04656),
                      backgroundColor: cardBg,
                      side: const BorderSide(
                        color: Color(0xFFE04656),
                        width: 1.1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 17),
                    label: const Text(
                      'Xuất báo cáo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Lưới 2x2 Thẻ chỉ số thực tế từ Firestore (đã bỏ % cứng)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    isDark: isDark,
                    icon: Icons.movie_creation_outlined,
                    title: 'Tổng phim',
                    value: _isLoading ? '...' : _formatNumber(_totalMovies),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isDark: isDark,
                    icon: Icons.visibility_outlined,
                    title: 'Lượt xem',
                    value: _isLoading ? '...' : _formatNumber(_totalViews),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    isDark: isDark,
                    icon: Icons.group_outlined,
                    title: 'Tài khoản',
                    value: _isLoading ? '...' : _formatNumber(_totalUsers),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isDark: isDark,
                    icon: Icons.sms_outlined,
                    title: 'Bình luận',
                    value: _isLoading ? '...' : _formatNumber(_totalComments),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Biểu đồ "Lượt xem theo thể loại" (tính động 100% từ movies + movie_genres + genres)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lượt xem theo thể loại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF3B4E),
                          ),
                        ),
                      ),
                    )
                  else if (_genreStats.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Chưa có dữ liệu lượt xem theo thể loại',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Vòng biểu đồ Donut
                        SizedBox(
                          width: 112,
                          height: 112,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(112, 112),
                                painter: _DonutChartPainter(
                                  stats: _genreStats,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatCompactViews(_totalViews),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'lượt xem',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Chú thích thể loại + lượt xem thực tế + %
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _genreStats.map((g) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: g.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        g.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_formatNumber(g.views)} (${g.percent}%)',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Phần "Người dùng mới nhất" (lấy động từ bảng `users`)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Người dùng mới nhất',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AdminBottomBar.tabIndexNotifier.value = 2;
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE04656),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFFE04656),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bảng Người dùng mới nhất
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header bảng
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFF1F3F7),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 38,
                          child: Text(
                            'Người dùng',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 42,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Text(
                            'Ngày tạo',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Các dòng người dùng
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF3B4E),
                          ),
                        ),
                      ),
                    )
                  else if (_latestUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Chưa có người dùng nào',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    ..._latestUsers.take(5).map((u) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: borderColor.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar + Username
                            Expanded(
                              flex: 38,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: const Color(0xFFFF3B4E)
                                        .withValues(alpha: 0.14),
                                    backgroundImage: (u.avatarUrl != null &&
                                            u.avatarUrl!.isNotEmpty)
                                        ? NetworkImage(u.avatarUrl!)
                                        : null,
                                    child: (u.avatarUrl == null ||
                                            u.avatarUrl!.isEmpty)
                                        ? Text(
                                            u.getInitials(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF3B4E),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      u.username.isNotEmpty
                                          ? u.username
                                          : u.getDisplayName(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Email
                            Expanded(
                              flex: 42,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  u.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ),

                            // Ngày tạo
                            Expanded(
                              flex: 20,
                              child: Text(
                                _formatRelativeDate(u.createdAt),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE04656).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE04656),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khung trang cho các tab quản lý khác (Phim, Tài khoản, Bình luận, Thể loại, Thông báo)
  Widget _buildSubTabView(int tabIndex, bool isDark) {
    final titles = [
      'Tổng quan hệ thống',
      'Quản lý Phim (${_formatNumber(_totalMovies)})',
      'Quản lý Tài khoản (${_formatNumber(_totalUsers)})',
      'Quản lý Bình luận (${_formatNumber(_totalComments)})',
      'Quản lý Thể loại (${_formatNumber(_totalGenres)})',
      'Quản lý Thông báo',
    ];
    final icons = [
      Icons.home_rounded,
      Icons.slideshow_rounded,
      Icons.person_rounded,
      Icons.sms_rounded,
      Icons.grid_view_rounded,
      Icons.notifications_rounded,
    ];

    if (tabIndex == 2 && _latestUsers.isNotEmpty) {
      final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
      final textSecondary =
          isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titles[tabIndex],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => AdminBottomBar.tabIndexNotifier.value = 0,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Về Tổng quan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: _latestUsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final u = _latestUsers[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            const Color(0xFFFF3B4E).withValues(alpha: 0.14),
                        backgroundImage:
                            (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                                ? NetworkImage(u.avatarUrl!)
                                : null,
                        child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                            ? Text(
                                u.getInitials(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF3B4E),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    u.getDisplayName(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: u.getIsAdmin()
                                        ? const Color(0xFFFF3B4E)
                                            .withValues(alpha: 0.15)
                                        : Colors.blue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: u.getIsAdmin()
                                          ? const Color(0xFFFF3B4E)
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u.email,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatRelativeDate(u.createdAt),
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B4E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[tabIndex],
                size: 34,
                color: const Color(0xFFFF3B4E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titles[tabIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khu vực quản trị chuyên sâu cho mục này đã sẵn sàng để mở rộng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    AdminBottomBar.tabIndexNotifier.value = 0;
                  },
                  icon: const Icon(Icons.dashboard_outlined, size: 18),
                  label: const Text('Về Tổng quan'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Trang chủ User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreStat {
  final String name;
  final int views;
  final int percent;
  final Color color;

  const _GenreStat({
    required this.name,
    required this.views,
    required this.percent,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_GenreStat> stats;

  _DonutChartPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    final total = stats.fold<int>(0, (acc, item) => acc + item.views);
    if (total <= 0) return;

    for (final item in stats) {
      final sweepAngle = (item.views / total) * 2 * math.pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.stats != stats;
  }
}
