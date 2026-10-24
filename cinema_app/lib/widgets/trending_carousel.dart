import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../pages/movie_detail_page.dart';

/// Carousel hiển thị danh sách phim "ĐANG THỊNH HÀNH" dạng cuộn ngang kèm nút chuyển trái/phải.
class TrendingCarousel extends StatefulWidget {
  final List<Movie> movies;

  const TrendingCarousel({
    super.key,
    required this.movies,
  });

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 260).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + 260).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề Section: "ĐANG THỊNH HÀNH"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ĐANG THỊNH HÀNH',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF4B5C),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Khung cuộn ngang có 2 nút mũi tên trái / phải
        SizedBox(
          height: 175,
          child: Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.movies.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final movie = widget.movies[index];
                  return _buildTrendingItem(movie, isDark);
                },
              ),

              // Nút cuộn trái
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _scrollLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Nút cuộn phải
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _scrollRight,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingItem(Movie movie, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailPage(movie: movie),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 115,
          height: 175,
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
                      _buildPlaceholder(isDark, movie.name),
                )
              else
                _buildPlaceholder(isDark, movie.name),

              // Lớp bóng mờ ở đáy poster
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Tên phim ở góc dưới poster
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  movie.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, String title) {
    return Container(
      color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE5E7EB),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_filter_rounded, size: 28, color: Color(0xFFFF4B5C)),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
