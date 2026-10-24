import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../providers/watchlist_provider.dart';
import 'player_page.dart';

/// Trang Chi tiết phim (Component 6 trong ảnh mẫu).
class MovieDetailPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailPage({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final WatchlistProvider _watchlist = WatchlistProvider.instance;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bannerImg = (movie.bannerUrl != null &&
            movie.bannerUrl!.isNotEmpty &&
            movie.bannerUrl != '{}')
        ? movie.bannerUrl
        : movie.posterUrl;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===== 1. APP BAR VỚI BANNER HÌNH ẢNH TO =====
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép liên kết: ${movie.name}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListenableBuilder(
                listenable: _watchlist,
                builder: (context, _) {
                  final isFav = _watchlist.isFavorite(movie.id);
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: isFav ? const Color(0xFFFF4B5C) : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      _watchlist.toggleFavorite(movie);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFav
                              ? 'Đã xóa khỏi danh sách yêu thích'
                              : 'Đã thêm vào danh sách yêu thích'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerImg != null && bannerImg.isNotEmpty && bannerImg != '{}')
                    Image.network(
                      bannerImg,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackBanner(),
                    )
                  else
                    _buildFallbackBanner(),

                  // Lớp phủ Gradient ở đáy
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark ? const Color(0xFF121212) : Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== 2. THÔNG TIN PHIM & NÚT HÀNH ĐỘNG =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên phim
                  Text(
                    movie.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata: Tâm lý · 16 tập · 2024 · ⭐ 9.2
                  Row(
                    children: [
                      Text(
                        _buildMetaString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB400)),
                      const SizedBox(width: 2),
                      Text(
                        movie.avgRating > 0
                            ? movie.avgRating.toStringAsFixed(1)
                            : '8.5',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Nút "Xem ngay" + Nút Bookmark
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                            label: const Text(
                              'Xem ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4B5C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerPage(movie: movie),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ListenableBuilder(
                        listenable: _watchlist,
                        builder: (context, _) {
                          final isFav = _watchlist.isFavorite(movie.id);
                          return Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.transparent : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: isFav ? const Color(0xFFFF4B5C) : const Color(0xFF4B5563),
                                size: 22,
                              ),
                              onPressed: () => _watchlist.toggleFavorite(movie),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ===== 3. NỘI DUNG TÓM TẮT =====
                  const Text(
                    'Nội dung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.description.isNotEmpty
                        ? movie.description
                        : 'Một câu chuyện tình yêu đầy trắc trở giữa hai con người đến từ hai thế giới khác nhau. Liệu họ có thể vượt qua số phận để ở bên nhau?',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== 4. DIỄN VIÊN =====
                  const Text(
                    'Diễn viên',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCastList(isDark),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildMetaString() {
    final type = widget.movie.getTypeLabel();
    final eps = widget.movie.totalEpisodes > 0 ? '${widget.movie.totalEpisodes} tập' : 'Phim lẻ';
    final year = widget.movie.releaseYear?.toString() ?? '2026';
    return '$type · $eps · $year ·';
  }

  Widget _buildCastList(bool isDark) {
    final cast = [
      {'name': 'Lee Min Ho', 'role': 'Nam chính', 'img': 'https://i.pravatar.cc/150?img=11'},
      {'name': 'Kim Ji Won', 'role': 'Nữ chính', 'img': 'https://i.pravatar.cc/150?img=5'},
      {'name': 'Park Seo Joon', 'role': 'Phụ vai', 'img': 'https://i.pravatar.cc/150?img=12'},
      {'name': 'Song Hye Kyo', 'role': 'Khách mời', 'img': 'https://i.pravatar.cc/150?img=9'},
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cast.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final c = cast[index];
          return Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(c['img']!),
                backgroundColor: const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 6),
              Text(
                c['name']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              Text(
                c['role']!,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      color: const Color(0xFF1F2937),
      child: const Center(
        child: Icon(Icons.movie_filter_rounded, size: 64, color: Colors.white24),
      ),
    );
  }
}
