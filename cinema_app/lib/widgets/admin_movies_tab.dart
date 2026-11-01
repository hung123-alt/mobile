import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../pages/admin_movie_edit_page.dart';

/// Giao diện Tab "Quản lý phim" dành cho Admin (theo wireframe).
class AdminMoviesTab extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminMoviesTab({super.key, this.onDataChanged});

  @override
  State<AdminMoviesTab> createState() => _AdminMoviesTabState();
}

class _AdminMoviesTabState extends State<AdminMoviesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<_AdminMovieItem> _allMovies = [];

  // Bộ lọc: 'all' | 'ongoing' | 'completed' | 'phim_le' | 'phim_bo'
  String _selectedFilter = 'all';
  String _sortBy = 'Mới nhất';
  final List<String> _sortOptions = const [
    'Mới nhất',
    'Lượt xem cao',
    'Tên A-Z',
    'Cũ nhất',
  ];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);

    try {
      final snap = await _firestore.collection(CollectionNames.movies).get();
      final items = <_AdminMovieItem>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final id = _parseInt(data['id'] ?? doc.id, 0);
        final title =
            (data['title'] ?? data['name'] ?? 'Chưa có tên').toString();
        final type = (data['type'] ?? 'phim_le').toString();
        final status = (data['status'] ?? 'ongoing').toString();
        final totalEpisodes = _parseInt(
          data['totalEpisodes'] ?? data['total_episodes'],
          1,
        );
        final viewCount = _parseInt(
          data['viewCount'] ?? data['view_count'],
          0,
        );
        final posterUrl =
            (data['posterUrl'] ?? data['poster_url'] ?? '').toString();
        final bannerUrl =
            (data['bannerUrl'] ?? data['banner_url'] ?? '').toString();
        final createdAtRaw =
            (data['createdAt'] ?? data['created_at'] ?? '').toString();
        final createdAt = DateTime.tryParse(createdAtRaw);

        items.add(
          _AdminMovieItem(
            docId: doc.id,
            id: id,
            title: title,
            type: type,
            status: status,
            totalEpisodes: totalEpisodes,
            viewCount: viewCount,
            posterUrl: posterUrl,
            bannerUrl: bannerUrl,
            createdAt: createdAt,
            rawData: data,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _allMovies = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminMoviesTab load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<_AdminMovieItem> get _filteredMovies {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allMovies.where((m) {
      if (query.isNotEmpty && !m.title.toLowerCase().contains(query)) {
        return false;
      }
      switch (_selectedFilter) {
        case 'ongoing':
          return m.status == 'ongoing';
        case 'completed':
          return m.status == 'completed';
        case 'phim_le':
          return m.type == 'phim_le';
        case 'phim_bo':
          return m.type == 'phim_bo';
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Lượt xem cao':
          return b.viewCount.compareTo(a.viewCount);
        case 'Tên A-Z':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'Cũ nhất':
          final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final cmp = dA.compareTo(dB);
          if (cmp != 0) return cmp;
          return a.id.compareTo(b.id);
        case 'Mới nhất':
        default:
          final dA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final cmp = dB.compareTo(dA);
          if (cmp != 0) return cmp;
          return b.id.compareTo(a.id);
      }
    });

    return filtered;
  }

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

  String _formatViewsLabel(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M lượt xem';
    }
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K lượt xem';
    }
    return '${_formatNumber(views)} lượt xem';
  }

  Future<void> _openEditMovie({_AdminMovieItem? movie}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMovieEditPage(
          movieDocId: movie?.docId,
          initialMovieData: movie?.rawData,
        ),
      ),
    );

    if (changed == true) {
      await _loadMovies();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _confirmAndDeleteMovie(_AdminMovieItem movie) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa phim'),
        content: Text(
          'Bạn có chắc chắn muốn xóa phim "${movie.title}" khỏi hệ thống không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa phim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore
          .collection(CollectionNames.movies)
          .doc(movie.docId)
          .delete();

      if (movie.id > 0) {
        final mgSnap = await _firestore
            .collection('movie_genres')
            .where('movie_id', isEqualTo: movie.id)
            .get();
        for (final doc in mgSnap.docs) {
          await doc.reference.delete();
        }
        final mcSnap = await _firestore
            .collection('movie_countries')
            .where('movie_id', isEqualTo: movie.id)
            .get();
        for (final doc in mcSnap.docs) {
          await doc.reference.delete();
        }
        final epSnap = await _firestore
            .collection(CollectionNames.episodes)
            .where('movie_id', isEqualTo: movie.id)
            .get();
        for (final doc in epSnap.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa phim "${movie.title}" thành công!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadMovies();
      widget.onDataChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa phim thất bại: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final movies = _filteredMovies;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề "Quản lý phim" + Nút "+ Thêm phim"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý phim',
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _openEditMovie(),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Thêm phim',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Thanh tìm kiếm phim
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phim (tên phim, diễn viên...)',
                hintStyle: TextStyle(fontSize: 13.5, color: textSecondary),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Hàng nút lọc nhanh (Đang chiếu, Hoàn thành, Phim lẻ, Phim bộ)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  keyName: 'ongoing',
                  label: 'Đang chiếu',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  keyName: 'completed',
                  label: 'Hoàn thành',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  keyName: 'phim_le',
                  label: 'Phim lẻ',
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  keyName: 'phim_bo',
                  label: 'Phim bộ',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Hàng Tổng số phim + Sắp xếp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Tổng: ',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '${_formatNumber(movies.length)} phim',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    'Sắp xếp:',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        dropdownColor: cardBg,
                        items: _sortOptions
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _sortBy = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Danh sách phim từ DB
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF3B4E),
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFF3B4E),
                    onRefresh: _loadMovies,
                    child: movies.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: Text(
                                  'Không tìm thấy phim phù hợp',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
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
                            itemCount: movies.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 18,
                              color: borderColor.withValues(alpha: 0.7),
                            ),
                            itemBuilder: (context, index) {
                              final movie = movies[index];
                              return _buildMovieRow(
                                movie: movie,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String keyName,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == keyName;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Bấm lại vào chip đang chọn thì bỏ lọc (về Tất cả)
          _selectedFilter = isSelected ? 'all' : keyName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF3B4E)
              : (isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF374151)),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieRow({
    required _AdminMovieItem movie,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isOngoing = movie.status == 'ongoing';
    final badgeBg = isOngoing
        ? const Color(0xFFDCFCE7)
        : (movie.status == 'completed'
            ? const Color(0xFFDBEAFE)
            : const Color(0xFFFEF3C7));
    final badgeText = isOngoing
        ? const Color(0xFF15803D)
        : (movie.status == 'completed'
            ? const Color(0xFF1D4ED8)
            : const Color(0xFFB45309));

    final imgUrl = movie.displayImageUrl;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openEditMovie(movie: movie),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ảnh thumbnail bo góc
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color:
                  isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
              child: imgUrl != null
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.movie_outlined,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  : const Icon(
                      Icons.movie_outlined,
                      color: Color(0xFF9CA3AF),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin phim (Tên + Badge trạng thái, Loại phim • Số tập, Lượt xem)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        movie.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.theaters_outlined,
                      size: 15,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${movie.typeLabel} • ${movie.totalEpisodes} tập',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 15,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatViewsLabel(movie.viewCount),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Nút Chỉnh sửa (cây bút)
          InkWell(
            onTap: () => _openEditMovie(movie: movie),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nút Xóa phim (thùng rác đỏ)
          InkWell(
            onTap: () => _confirmAndDeleteMovie(movie),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 21,
                color: Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMovieItem {
  final String docId;
  final int id;
  final String title;
  final String type;
  final String status;
  final int totalEpisodes;
  final int viewCount;
  final String posterUrl;
  final String bannerUrl;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  const _AdminMovieItem({
    required this.docId,
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.totalEpisodes,
    required this.viewCount,
    required this.posterUrl,
    required this.bannerUrl,
    required this.createdAt,
    required this.rawData,
  });

  String? get displayImageUrl {
    String? raw;
    if (posterUrl.isNotEmpty && posterUrl != '{}') {
      raw = posterUrl;
    } else if (bannerUrl.isNotEmpty && bannerUrl != '{}') {
      raw = bannerUrl;
    }
    if (raw == null) return null;
    if (kIsWeb && raw.startsWith('http')) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(raw)}';
    }
    return raw;
  }

  String get typeLabel {
    switch (type) {
      case 'phim_bo':
        return 'Phim bộ';
      case 'phim_le':
        return 'Phim lẻ';
      case 'hoat_hinh':
        return 'Hoạt hình';
      case 'anime':
        return 'Anime';
      default:
        return 'Phim lẻ';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'ongoing':
        return 'Đang chiếu';
      case 'completed':
        return 'Hoàn thành';
      case 'upcoming':
        return 'Sắp chiếu';
      default:
        return 'Đang chiếu';
    }
  }
}

