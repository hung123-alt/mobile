import 'package:flutter/material.dart';

import '../models/genre_model.dart';
import '../services/firestore_movie_service.dart';
import '../widgets/app_top_navbar.dart';
import 'search_page.dart';

/// Trang Thể loại — đã fix đếm thiếu phim.
///
/// Dùng [FirestoreMovieService.fetchEnrichedMovies] nên số lượng mỗi thẻ
/// đếm từ bảng trung gian `movie_genres` (đúng với data migrate MySQL cũ),
/// không còn chỉ đếm mảng nhúng rỗng. Bấm vào thẻ -> sang SearchPage
/// lọc sẵn theo `genreId` nên Hành động hiện đủ phim thay vì 3 phim.
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  static const List<Map<String, dynamic>> _fallbackCategories = [
    {
      'name': 'Hành động',
      'slug': 'hanh-dong',
      'colors': [Color(0xFF8B0000), Color(0xFFE50914)],
      'img': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&q=80',
    },
    {
      'name': 'Tình cảm',
      'slug': 'tinh-cam',
      'colors': [Color(0xFFC2185B), Color(0xFFF06292)],
      'img': 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=400&q=80',
    },
    {
      'name': 'Kinh dị',
      'slug': 'kinh-di',
      'colors': [Color(0xFF004D40), Color(0xFF00796B)],
      'img': 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=400&q=80',
    },
    {
      'name': 'Hài',
      'slug': 'hai-huoc',
      'colors': [Color(0xFFE65100), Color(0xFFFFA726)],
      'img': 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=400&q=80',
    },
    {
      'name': 'Hoạt hình',
      'slug': 'hoat-hinh',
      'colors': [Color(0xFF1565C0), Color(0xFF42A5F5)],
      'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&q=80',
    },
    {
      'name': 'Viễn tưởng',
      'slug': 'vien-tuong',
      'colors': [Color(0xFF4A148C), Color(0xFF7E57C2)],
      'img': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&q=80',
    },
    {
      'name': 'Tâm lý',
      'slug': 'tam-ly',
      'colors': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      'img': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=400&q=80',
    },
    {
      'name': 'Phiêu lưu',
      'slug': 'phieu-luu',
      'colors': [Color(0xFF006064), Color(0xFF26C6DA)],
      'img': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=400&q=80',
    },
    {
      'name': 'Cổ trang',
      'slug': 'co-trang',
      'colors': [Color(0xFF512DA8), Color(0xFF9575CD)],
      'img': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&q=80',
    },
    {
      'name': 'Gia đình',
      'slug': 'gia-dinh',
      'colors': [Color(0xFF37474F), Color(0xFF78909C)],
      'img': 'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400&q=80',
    },
  ];

  static const List<Color> _palette = [
    Color(0xFFE50914),
    Color(0xFFEC4899),
    Color(0xFF00796B),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF22C55E),
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
    Color(0xFF64748B),
  ];

  List<Genre> _genres = [];
  Map<int, int> _counts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final movies = await FirestoreMovieService.fetchEnrichedMovies();
      final genreMap = await FirestoreMovieService.fetchGenreMap();
      final counts = await FirestoreMovieService.countMoviesPerGenre(movies);
      final genres = genreMap.values.toList()
        ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
      if (!mounted) return;
      setState(() {
        _genres = genres;
        _counts = counts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openGenre(int id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          initialGenreId: id,
          initialGenreName: name,
          initialQuery: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final useDynamic = _genres.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppTopNavbar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thể loại',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (!_isLoading)
                    Text(
                      useDynamic
                          ? '${_genres.length} thể loại'
                          : '${_fallbackCategories.length} thể loại',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF4B5C)))
                  : RefreshIndicator(
                      color: const Color(0xFFFF4B5C),
                      onRefresh: _load,
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        itemCount: useDynamic
                            ? _genres.length
                            : _fallbackCategories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          if (useDynamic) {
                            final g = _genres[index];
                            final count = _counts[g.id] ?? 0;
                            final colors = [
                              _palette[index % _palette.length],
                              _palette[index % _palette.length]
                                  .withValues(alpha: 0.7),
                            ];
                            return _buildTile(
                              name: g.getName(),
                              badge: '$count phim',
                              colors: colors,
                              img: null,
                              onTap: () => _openGenre(g.id, g.getName()),
                            );
                          }
                          final cat = _fallbackCategories[index];
                          final List<Color> colors = cat['colors'];
                          return _buildTile(
                            name: cat['name'],
                            badge: null,
                            colors: colors,
                            img: cat['img'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SearchPage(initialQuery: cat['name']),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required String name,
    String? badge,
    required List<Color> colors,
    String? img,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (img != null)
                Opacity(
                  opacity: 0.28,
                  child: Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
