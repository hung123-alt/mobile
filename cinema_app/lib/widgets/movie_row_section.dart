import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../pages/movie_detail_page.dart';
import 'movie_card.dart';

/// Dải phim ngang theo chủ đề (VD: Phim Hàn, Phim Trung, Hành động...).
///
/// Dùng chung cho trang chủ: tiêu đề + phụ đề thơ + nút "Xem tất cả" + list ngang.
class MovieRowSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Movie> movies;
  final VoidCallback? onSeeAll;

  const MovieRowSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.movies,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 17,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 208,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return SizedBox(
                width: 118,
                child: MovieCard(
                  movie: movie,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailPage(movie: movie),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
