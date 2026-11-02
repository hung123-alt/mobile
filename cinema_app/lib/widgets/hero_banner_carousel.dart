import 'dart:async';

import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../pages/movie_detail_page.dart';

/// Hero Banner carousel kiểu Netflix cho trang chủ.
///
/// - Tự động chuyển slide mỗi 5s, vuốt tay, chấm chỉ báo.
/// - Ảnh nền 16:9 bo góc, phủ gradient đen từ dưới lên để chữ đọc được.
/// - Badge Thể loại + Lượt xem + Điểm, tiêu đề 2 dòng, mô tả 2 dòng.
/// - 2 nút: Xem ngay (đỏ) + Chi tiết (trắng mờ).
class HeroBannerCarousel extends StatefulWidget {
  final List<Movie> movies;

  const HeroBannerCarousel({super.key, required this.movies});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  static const Color primaryColor = Color(0xFFFF4B5C);

  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.movies.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final next = (_current + 1) % widget.movies.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openDetail(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.movies.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _openDetail(movie),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (movie.displayImageUrl != null)
                          Image.network(
                            movie.displayImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildFallback(isDark, movie),
                          )
                        else
                          _buildFallback(isDark, movie),
                        // Gradient đọc chữ
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.88),
                              ],
                              stops: const [0.35, 0.65, 1.0],
                            ),
                          ),
                        ),
                        // Badge top-left: nổi bật / lượt xem
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Row(
                            children: [
                              if (movie.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Text(
                                    'NỔI BẬT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              if (movie.isFeatured) const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.visibility_outlined,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      movie.getViewCountLabel(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (movie.avgRating > 0) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: Color(0xFFFFB400),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        movie.avgRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Thông tin đáy banner
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (movie.genres.isNotEmpty)
                                Text(
                                  movie.genres
                                      .take(3)
                                      .map((g) => g.getName())
                                      .join(' • ')
                                      .toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFFC9CE),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              const SizedBox(height: 3),
                              Text(
                                movie.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black54, blurRadius: 6)
                                  ],
                                ),
                              ),
                              if (movie.description.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    movie.description.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 34,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openDetail(movie),
                                        icon: const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 18,
                                            color: Colors.white),
                                        label: const Text(
                                          'Xem ngay',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 34,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openDetail(movie),
                                        icon: const Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: Colors.white),
                                        label: const Text(
                                          'Chi tiết',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Colors.white70),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.12),
                                        ),
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
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Chấm chỉ báo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.movies.length > 8 ? 8 : widget.movies.length,
              (i) {
            final active = i == (_current % (widget.movies.length > 8 ? 8 : widget.movies.length));
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? primaryColor : Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFallback(bool isDark, Movie movie) {
    return Container(
      color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_filter_rounded,
              size: 40, color: Color(0xFFFF4B5C)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              movie.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
