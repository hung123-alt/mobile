import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../pages/movie_detail_page.dart';

/// Thẻ hiển thị phim thu nhỏ (MovieCard) dùng trong Lưới (Grid) và Danh sách ngang.
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailPage(movie: movie),
              ),
            );
          },
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster hình ảnh
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (movie.posterUrl != null &&
                          movie.posterUrl!.isNotEmpty &&
                          movie.posterUrl != '{}')
                        Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(isDark),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFFFF4B5C).withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        _buildPlaceholder(isDark),

                      // Badge điểm đánh giá hoặc số tập ở góc trên
                      if (movie.avgRating > 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB400)),
                                const SizedBox(width: 2),
                                Text(
                                  movie.avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Tiêu đề phim (1-2 dòng)
            Text(
              movie.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),

            // Phụ đề (Thể loại / Kiểu phim · Số tập)
            Text(
              _buildSubtitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final typeLabel = movie.getTypeLabel();
    final eps = movie.totalEpisodes > 0 ? '${movie.totalEpisodes} tập' : 'Phim lẻ';
    return '$typeLabel · $eps';
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 28,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            'PhimHay24h',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
