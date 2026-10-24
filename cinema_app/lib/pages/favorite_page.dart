import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../providers/theme_provider.dart';
import '../providers/watchlist_provider.dart';
import 'movie_detail_page.dart';

/// Trang Yêu thích (Component 4 trong ảnh mẫu).
class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final WatchlistProvider _watchlist = WatchlistProvider.instance;

  @override
  void initState() {
    super.initState();
    _watchlist.loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'PhimHay',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: '24h',
                          style: TextStyle(
                            color: Color(0xFFFF4B5C),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: ThemeProvider.instance,
                    builder: (context, _) => IconButton(
                      icon: Icon(
                        ThemeProvider.instance.isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 22,
                        color: isDark ? Colors.amber : const Color(0xFF4B5563),
                      ),
                      onPressed: () => ThemeProvider.instance.toggleTheme(),
                    ),
                  ),
                ],
              ),
            ),

            // Tiêu đề: "Yêu thích"
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Yêu thích',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // Danh sách phim yêu thích
            Expanded(
              child: ListenableBuilder(
                listenable: _watchlist,
                builder: (context, _) {
                  final list = _watchlist.favorites;

                  if (_watchlist.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF4B5C)),
                    );
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_outline_rounded,
                            size: 64,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Chưa có phim yêu thích',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bấm vào biểu tượng trái tim ở phim bất kỳ để lưu lại.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final movie = list[index];
                      return _buildFavoriteItem(movie, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(Movie movie, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MovieDetailPage(movie: movie)),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 72,
                color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                child: movie.posterUrl != null &&
                        movie.posterUrl!.isNotEmpty &&
                        movie.posterUrl != '{}'
                    ? Image.network(
                        movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.movie_outlined, size: 24, color: Colors.grey),
                      )
                    : const Icon(Icons.movie_outlined, size: 24, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 14),

            // Tên và thông tin phim
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.totalEpisodes > 0 ? 'Tập ${movie.totalEpisodes}' : 'Phim lẻ'} · ${movie.getTypeLabel()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            // Nút trái tim đỏ
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Color(0xFFFF4B5C), size: 20),
              onPressed: () => _watchlist.toggleFavorite(movie),
            ),

            // Mũi tên >
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }
}
