import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../widgets/admin_bottom_bar.dart';
import '../widgets/admin_comments_tab.dart';
import '../widgets/admin_genres_tab.dart';
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
  int _totalPhimLe = 0;
  int _totalPhimBo = 0;
  int _totalOngoing = 0;
  int _totalCompleted = 0;
  String _period = 'all';
  List<_TopMovie> _topMovies = [];
  List<_GenreCount> _genreCounts = [];
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
    if (!mounted) return;
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

      // 2. Mốc thời gian bắt đầu theo bộ lọc "Thời gian" đang chọn
      final start = _periodStart();
      bool inPeriod(dynamic raw) {
        if (start == null) return true;
        final d = _parseDate(raw);
        return d != null && !d.isBefore(start);
      }

      // 3. Thống kê phim trong khoảng thời gian đang lọc
      int viewsSum = 0;
      int phimLe = 0;
      int phimBo = 0;
      int ongoing = 0;
      int completed = 0;
      final Map<int, int> movieViewsById = {};
      final Map<String, int> genreViewMap = {};
      final Map<String, int> genreCountMap = {};
      final List<_TopMovie> topMovies = [];

      for (final doc in moviesSnap.docs) {
        final data = doc.data();
        if (!inPeriod(data['createdAt'] ?? data['created_at'])) continue;

        final mId = _parseInt(data['id'] ?? doc.id);
        final views = _parseInt(data['viewCount'] ?? data['view_count']);
        final type = (data['type'] ?? '').toString().trim();
        final status = (data['status'] ?? '').toString().trim();
        final title = (data['name'] ?? data['title'] ?? '').toString().trim();

        viewsSum += views;
        if (mId > 0) {
          movieViewsById[mId] = views;
          topMovies.add(
            _TopMovie(
              name: title.isEmpty ? 'Phim #$mId' : title,
              views: views,
            ),
          );
        }
        if (type == 'phim_le') phimLe++;
        if (type == 'phim_bo') phimBo++;
        if (status == 'ongoing') ongoing++;
        if (status == 'completed') completed++;

        // Phim có nhúng sẵn mảng genres trong document movie
        final embeddedGenres = data['genres'] ?? data['genreNames'];
        if (embeddedGenres is List && embeddedGenres.isNotEmpty) {
          for (final g in embeddedGenres) {
            final gName = g is Map
                ? (g['name'] ?? g['title'] ?? '').toString().trim()
                : g.toString().trim();
            if (gName.isNotEmpty) {
              genreViewMap[gName] = (genreViewMap[gName] ?? 0) + views;
              genreCountMap[gName] = (genreCountMap[gName] ?? 0) + 1;
            }
          }
        }
      }

      // 4. Kết nối bảng `movie_genres` (movie_id, genre_id)
      for (final doc in movieGenresSnap.docs) {
        final data = doc.data();
        final mId = _parseInt(data['movie_id'] ?? data['movieId']);
        final gId = _parseInt(data['genre_id'] ?? data['genreId']);
        final gName = genreNamesById[gId];
        if (gName != null && movieViewsById.containsKey(mId)) {
          final views = movieViewsById[mId] ?? 0;
          genreViewMap[gName] = (genreViewMap[gName] ?? 0) + views;
          genreCountMap[gName] = (genreCountMap[gName] ?? 0) + 1;
        }
      }

      // 5. Tỷ lệ % thực tế cho biểu đồ Lượt xem theo thể loại
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

      // 6. Số lượng phim theo thể loại (cho biểu đồ cột ngang)
      final genreCounts = genreCountMap.entries
          .map((e) => _GenreCount(name: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      // 7. Top 10 phim xem nhiều nhất
      topMovies.sort((a, b) => b.views.compareTo(a.views));

      // 8. Bình luận trong khoảng thời gian đang lọc
      int commentsCount = 0;
      for (final doc in commentsSnap.docs) {
        final data = doc.data();
        if (inPeriod(data['createdAt'] ?? data['created_at'])) {
          commentsCount++;
        }
      }

      // 9. Danh sách người dùng mới nhất từ bảng `users`
      final parsedUsers = <User>[];
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        if (!inPeriod(data['createdAt'] ?? data['created_at'])) continue;
        try {
          parsedUsers.add(User.fromJson(data));
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
        _totalComments = commentsCount;
        _totalGenres = genresSnap.size;
        _totalPhimLe = phimLe;
        _totalPhimBo = phimBo;
        _totalOngoing = ongoing;
        _totalCompleted = completed;
        _latestUsers = parsedUsers;
        _genreStats = computedGenres;
        _genreCounts = genreCounts;
        _topMovies = topMovies.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminDashboard load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Mốc bắt đầu của khoảng thời gian đang lọc (null = toàn thời gian).
  DateTime? _periodStart() {
    final now = DateTime.now();
    switch (_period) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case 'this_month':
        return DateTime(now.year, now.month);
      case 'this_year':
        return DateTime(now.year);
      default:
        return null;
    }
  }

  /// Đọc ngày tháng từ Firestore (Timestamp) hoặc chuỗi ISO.
  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    return DateTime.tryParse(raw.toString());
  }

  /// Tỷ lệ % an toàn (tránh chia cho 0).
  int _percentOf(int part, int total) {
    if (total <= 0) return 0;
    return ((part / total) * 100).round();
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
                  if (tabIndex == 3) {
                    return AdminCommentsTab(
                      onDataChanged: _loadDashboardData,
                    );
                  }
                  if (tabIndex == 4) {
                    return AdminGenresTab(
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
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    // Biểu đồ tròn: Tỷ lệ định dạng phim + Trạng thái trình chiếu
    final typeTotal = _totalPhimLe + _totalPhimBo;
    final typeStats = <_GenreStat>[
      _GenreStat(
        name: 'Phim Lẻ',
        views: _totalPhimLe,
        percent: _percentOf(_totalPhimLe, typeTotal),
        color: const Color(0xFF8B5CF6),
      ),
      _GenreStat(
        name: 'Phim Bộ',
        views: _totalPhimBo,
        percent: _percentOf(_totalPhimBo, typeTotal),
        color: const Color(0xFFEC4899),
      ),
    ];
    final statusTotal = _totalOngoing + _totalCompleted;
    final statusStats = <_GenreStat>[
      _GenreStat(
        name: 'Đang chiếu',
        views: _totalOngoing,
        percent: _percentOf(_totalOngoing, statusTotal),
        color: const Color(0xFFF59E0B),
      ),
      _GenreStat(
        name: 'Hoàn thành',
        views: _totalCompleted,
        percent: _percentOf(_totalCompleted, statusTotal),
        color: const Color(0xFF10B981),
      ),
    ];

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
            // ===== 1. BREADCRUMB =====
            Row(
              children: [
                Text(
                  'Trang chủ',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '›',
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Text(
                  'Bảng điều khiển',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ===== 2. TIÊU ĐỀ =====
            Text(
              'Tổng quan hệ thống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // ===== 3. THANH CÔNG CỤ: BỘ LỌC THỜI GIAN + XUẤT BÁO CÁO =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor.withValues(alpha: 0.7)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Thời gian',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF262626)
                              : const Color(0xFFF1F3F7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor.withValues(alpha: 0.8),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _period,
                            isDense: true,
                            iconSize: 18,
                            borderRadius: BorderRadius.circular(10),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Toàn thời gian'),
                              ),
                              DropdownMenuItem(
                                value: '7d',
                                child: Text('7 ngày qua'),
                              ),
                              DropdownMenuItem(
                                value: '30d',
                                child: Text('30 ngày qua'),
                              ),
                              DropdownMenuItem(
                                value: 'this_month',
                                child: Text('Tháng này'),
                              ),
                              DropdownMenuItem(
                                value: 'this_year',
                                child: Text('Năm nay'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _period = v);
                              _loadDashboardData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _handleExportReport,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE04656),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 17),
                    label: const Text(
                      'Xuất báo cáo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== 4. LƯỚI 8 THẺ CHỈ SỐ =====
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                final columns = wide ? 4 : 2;
                final cards = <Widget>[
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.movie_creation_outlined,
                    title: 'Tổng số phim',
                    value: _isLoading ? '...' : _formatNumber(_totalMovies),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.movie_filter_outlined,
                    title: 'Phim lẻ',
                    value: _isLoading ? '...' : _formatNumber(_totalPhimLe),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.live_tv_outlined,
                    title: 'Phim bộ',
                    value: _isLoading ? '...' : _formatNumber(_totalPhimBo),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Đang chiếu',
                    value: _isLoading ? '...' : _formatNumber(_totalOngoing),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Hoàn thành',
                    value: _isLoading ? '...' : _formatNumber(_totalCompleted),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.visibility_outlined,
                    title: 'Tổng lượt xem',
                    value: _isLoading ? '...' : _formatNumber(_totalViews),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.group_outlined,
                    title: 'Tổng tài khoản',
                    value: _isLoading ? '...' : _formatNumber(_totalUsers),
                  ),
                  _buildStatCard(
                    isDark: isDark,
                    icon: Icons.sms_outlined,
                    title: 'Bình luận',
                    value: _isLoading ? '...' : _formatNumber(_totalComments),
                  ),
                ];
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: wide ? 2.6 : 1.95,
                  children: cards,
                );
              },
            ),
            const SizedBox(height: 18),

            // ===== 5. HAI BIỂU ĐỒ TRÒN: ĐỊNH DẠNG PHIM & TRẠNG THÁI =====
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 560;
                final donutType = _buildDonutCard(
                  title: 'Tỷ lệ Định dạng Phim',
                  stats: typeStats,
                  centerValue: _formatNumber(typeTotal),
                  centerLabel: 'phim',
                  emptyText: 'Chưa có dữ liệu định dạng phim',
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                );
                final donutStatus = _buildDonutCard(
                  title: 'Trạng thái Trình chiếu',
                  stats: statusStats,
                  centerValue: _formatNumber(statusTotal),
                  centerLabel: 'phim',
                  emptyText: 'Chưa có dữ liệu trạng thái',
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: donutType),
                      const SizedBox(width: 16),
                      Expanded(child: donutStatus),
                    ],
                  );
                }
                return Column(
                  children: [
                    donutType,
                    const SizedBox(height: 16),
                    donutStatus,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ===== 5b. BIỂU ĐỒ DONUT: LƯỢT XEM THEO THỂ LOẠI =====
            _buildDonutCard(
              title: 'Lượt xem theo thể loại',
              stats: _genreStats,
              centerValue: _formatCompactViews(_totalViews),
              centerLabel: 'lượt xem',
              emptyText: 'Chưa có dữ liệu lượt xem theo thể loại',
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),

            // ===== 6. BIỂU ĐỒ CỘT: TOP 10 PHIM XEM NHIỀU NHẤT =====
            _buildChartSection(
              title: 'Top 10 Phim Xem Nhiều Nhất',
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
              child: _isLoading
                  ? const Padding(
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
                  : _topMovies.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Chưa có dữ liệu lượt xem',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 220,
                          child: CustomPaint(
                            size: const Size(double.infinity, 220),
                            painter: _BarChartPainter(
                              movies: _topMovies,
                              labelColor: textSecondary,
                              gridColor: gridColor,
                            ),
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // ===== 7. BIỂU ĐỒ CỘT NGANG: PHIM THEO THỂ LOẠI =====
            _buildChartSection(
              title: 'Thống kê Phim theo Thể loại',
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
              child: _isLoading
                  ? const Padding(
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
                  : _genreCounts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Chưa có dữ liệu thể loại',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: _genreCounts.length * 30.0 + 12,
                          child: CustomPaint(
                            size: Size(
                              double.infinity,
                              _genreCounts.length * 30.0 + 12,
                            ),
                            painter: _HBarChartPainter(
                              counts: _genreCounts,
                              labelColor: textSecondary,
                              valueColor: textPrimary,
                              gridColor: gridColor,
                            ),
                          ),
                        ),
            ),
            const SizedBox(height: 18),

            // ===== 8. BẢNG NGƯỜI DÙNG MỚI NHẤT (có cột STT) =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tài khoản mới đăng ký gần đây',
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
                          flex: 10,
                          child: Text(
                            'STT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 34,
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
                          flex: 38,
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
                          flex: 18,
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
                    ..._latestUsers.take(8).toList().asMap().entries.map((e) {
                      final idx = e.key;
                      final u = e.value;
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
                            Expanded(
                              flex: 10,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 34,
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
                            Expanded(
                              flex: 38,
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
                            Expanded(
                              flex: 18,
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

  /// Khung biểu đồ dùng chung (nền + viền + tiêu đề).
  Widget _buildChartSection({
    required String title,
    required Widget child,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Thẻ biểu đồ tròn kèm chú thích.
  Widget _buildDonutCard({
    required String title,
    required List<_GenreStat> stats,
    required String centerValue,
    required String centerLabel,
    required String emptyText,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty || stats.every((e) => e.views <= 0))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                emptyText,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            )
          else
            Column(
              children: [
                Center(
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(132, 132),
                          painter: _DonutChartPainter(stats: stats),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerValue,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              centerLabel,
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
                ),
                const SizedBox(height: 14),
                ...stats.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: e.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.name,
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
                          '${_formatNumber(e.views)} (${e.percent}%)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
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

class _TopMovie {
  final String name;
  final int views;

  const _TopMovie({required this.name, required this.views});
}

class _GenreCount {
  final String name;
  final int count;

  const _GenreCount({required this.name, required this.count});
}

/// Biểu đồ cột đứng: Top phim xem nhiều nhất.
class _BarChartPainter extends CustomPainter {
  final List<_TopMovie> movies;
  final Color labelColor;
  final Color gridColor;

  static const List<Color> _colors = [
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
  ];

  _BarChartPainter({
    required this.movies,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (movies.isEmpty || size.width <= 0) return;

    var maxValue = 0;
    for (final m in movies) {
      if (m.views > maxValue) maxValue = m.views;
    }
    if (maxValue <= 0) return;

    const topPad = 20.0;
    const bottomPad = 26.0;
    const leftPad = 4.0;
    final chartHeight = size.height - topPad - bottomPad;
    final chartWidth = size.width - leftPad;

    // Đường lưới ngang
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartHeight * i / 4;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
    }

    final slot = chartWidth / movies.length;
    final barWidth = math.min(26.0, slot * 0.55);

    for (int i = 0; i < movies.length; i++) {
      final m = movies[i];
      final h = (m.views / maxValue) * chartHeight;
      final x = leftPad + slot * i + (slot - barWidth) / 2;
      final rect = Rect.fromLTWH(x, topPad + chartHeight - h, barWidth, h);
      final paint = Paint()..color = _colors[i % _colors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );

      _paintLabel(
        canvas,
        _compact(m.views),
        Offset(x + barWidth / 2, topPad + chartHeight - h - 9),
        10,
        labelColor,
        slot,
      );
      _paintLabel(
        canvas,
        _truncate(m.name, 8),
        Offset(x + barWidth / 2, topPad + chartHeight + 11),
        9,
        labelColor,
        slot,
      );
    }
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    double maxWidth,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(10, maxWidth));
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  String _truncate(String s, int maxChars) {
    if (s.length <= maxChars) return s;
    return '${s.substring(0, maxChars)}…';
  }

  String _compact(int v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return '$v';
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.movies != movies ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.gridColor != gridColor;
  }
}

/// Biểu đồ cột ngang: số lượng phim theo thể loại.
class _HBarChartPainter extends CustomPainter {
  final List<_GenreCount> counts;
  final Color labelColor;
  final Color valueColor;
  final Color gridColor;

  static const List<Color> _colors = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
  ];

  _HBarChartPainter({
    required this.counts,
    required this.labelColor,
    required this.valueColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty || size.width <= 0) return;

    var maxValue = 0;
    for (final c in counts) {
      if (c.count > maxValue) maxValue = c.count;
    }
    if (maxValue <= 0) return;

    const rowHeight = 30.0;
    final labelWidth = math.min(96.0, size.width * 0.32);
    final valueWidth = 42.0;
    final barArea = math.max(
      20.0,
      size.width - labelWidth - valueWidth - 8,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i < counts.length; i++) {
      final c = counts[i];
      final y = i * rowHeight;
      final barHeight = 14.0;
      final barY = y + (rowHeight - barHeight) / 2;

      // Đường lưới dọc
      for (int g = 0; g <= 4; g++) {
        final gx = labelWidth + barArea * g / 4;
        canvas.drawLine(
          Offset(gx, y + 2),
          Offset(gx, y + rowHeight - 2),
          gridPaint,
        );
      }

      // Nhãn thể loại
      final labelTp = TextPainter(
        text: TextSpan(
          text: c.name,
          style: TextStyle(
            fontSize: 11.5,
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelWidth - 8);
      labelTp.paint(
        canvas,
        Offset(0, barY + (barHeight - labelTp.height) / 2),
      );

      // Thanh
      final w = (c.count / maxValue) * barArea;
      final paint = Paint()..color = _colors[i % _colors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(labelWidth, barY, math.max(2.0, w), barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Giá trị
      final valueTp = TextPainter(
        text: TextSpan(
          text: '${c.count}',
          style: TextStyle(
            fontSize: 11.5,
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
      )..layout();
      valueTp.paint(
        canvas,
        Offset(
          labelWidth + math.max(2.0, w) + 6,
          barY + (barHeight - valueTp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HBarChartPainter oldDelegate) {
    return oldDelegate.counts != counts ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.valueColor != valueColor;
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
