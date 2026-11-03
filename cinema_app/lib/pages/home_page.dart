import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../models/movie_model.dart';
import '../services/firestore_movie_service.dart';
import '../widgets/app_top_navbar.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_row_section.dart';
import 'search_page.dart';

/// Trang chủ PhimHay24h — bản dựng lại.
///
/// FIX RỚT PHIM:
/// Trước đây đọc `movies` rồi dùng `movie.genres` nhúng sẵn (thường rỗng vì
/// data migrate MySQL cũ chỉ lưu ở `movie_genres`), nên thể loại nào cũng ít.
/// Giờ dùng [FirestoreMovieService.fetchEnrichedMovies] đọc gộp 5 collections
/// nên admin báo 71 phim thì app hiện đủ 71 phim.
///
/// UI MỚI:
/// Hero Banner carousel + các dải phim theo chủ đề + lưới Mới cập nhật.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFFFF4B5C);

  List<Movie> _allMovies = [];
  List<Movie> _heroMovies = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  // =====================================================
  // 1. TẢI + ENRICH PHIM TỪ FIRESTORE
  // =====================================================
  Future<void> _fetchMovies() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loaded = await FirestoreMovieService.fetchEnrichedMovies();

      // Hero: ưu tiên isFeatured, thiếu thì top view
      final featured = loaded.where((m) => m.isFeatured).toList();
      List<Movie> hero;
      if (featured.length >= 5) {
        featured.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        hero = featured.take(8).toList();
      } else {
        final sorted = List<Movie>.from(loaded)
          ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
        hero = sorted.take(loaded.length >= 8 ? 8 : loaded.length).toList();
      }

      if (!mounted) return;
      setState(() {
        _allMovies = loaded;
        _heroMovies = hero;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải danh sách phim: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách phim.\nVui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // 2. HELPERS PHÂN LOẠI THEO QUỐC GIA / THỂ LOẠI
  // =====================================================

  bool _hasCountry(Movie m, List<String> slugs) {
    final set = slugs.map((s) => s.toLowerCase()).toSet();
    return m.countries.any((c) {
      final slug = c.slug.toLowerCase().trim();
      final name = c.getName().toLowerCase();
      if (set.contains(slug)) return true;
      // Phòng khi slug migrate lệch: so tên gần đúng
      for (final s in set) {
        if (name.contains(s.replaceAll('-', ' '))) return true;
      }
      return false;
    });
  }

  bool _hasGenre(Movie m, List<String> slugs) {
    final set = slugs.map((s) => s.toLowerCase()).toSet();
    return m.genres.any((g) {
      final slug = g.slug.toLowerCase().trim();
      final name = g.getName().toLowerCase();
      if (set.contains(slug)) return true;
      for (final s in set) {
        if (name.contains(s.replaceAll('-', ' '))) return true;
      }
      return false;
    });
  }

  bool _hasType(Movie m, List<String> types) => types.contains(m.type);

  List<Movie> _topViews(int n) {
    final sorted = List<Movie>.from(_allMovies)
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted.take(n > sorted.length ? sorted.length : n).toList();
  }

  void _openSearchWithGenre(int genreId, String genreName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          initialGenreId: genreId,
          initialGenreName: genreName,
        ),
      ),
    );
  }

  int? _genreIdBySlug(String slug) {
    for (final m in _allMovies) {
      for (final g in m.genres) {
        if (g.slug.toLowerCase() == slug) return g.id;
      }
    }
    return null;
  }

  // =====================================================
  // 3. ĐIỀU HƯỚNG
  // =====================================================
  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  void _openRandomPage() {
    Navigator.pushNamed(context, AppRoutes.random);
  }

  // =====================================================
  // 4. WIDGET CON
  // =====================================================
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: _openSearchPage,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242424) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: isDark ? Colors.grey[400] : const Color(0xFF9CA3AF),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Tìm tên phim, thể loại, quốc gia...',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF9CA3AF),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRandomButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: _openRandomPage,
          icon: const Icon(Icons.shuffle_rounded,
              color: primaryColor, size: 20),
          label: Text(
            'Phim ngẫu nhiên · ${_allMovies.length} phim đang chiếu',
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: primaryColor),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor:
                isDark ? const Color(0xFF241C20) : const Color(0xFFFFF3F4),
            side: const BorderSide(color: primaryColor, width: 1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const AppTopNavbar(),
            _buildSearchBar(isDark),
            _buildRandomButton(isDark),
            const SizedBox(height: 6),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage != null
                      ? _buildError()
                      : _buildHomeContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Đã xảy ra lỗi.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchMovies,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Thử lại',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_allMovies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Chưa có phim nào được cập nhật',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final trending = _topViews(10);
    final korean = _allMovies
        .where((m) => _hasCountry(m, ['han-quoc']))
        .take(12)
        .toList();
    final chinese = _allMovies
        .where((m) => _hasCountry(
            m, ['trung-quoc', 'dai-loan', 'hong-kong']))
        .take(12)
        .toList();
    final usEu = _allMovies
        .where((m) => _hasCountry(m, ['au-my', 'anh', 'my']))
        .take(12)
        .toList();
    final magic = _allMovies
        .where((m) => _hasGenre(
            m, ['vien-tuong', 'than-thoai', 'khoa-huyen', 'bi-an', 'kinh-di']))
        .take(12)
        .toList();
    final romance = _allMovies
        .where((m) =>
            _hasGenre(m, ['tinh-cam', 'tam-ly', 'gia-dinh', 'tinh-cam-lang-man']))
        .take(12)
        .toList();
    final action = _allMovies
        .where((m) => _hasGenre(
            m, ['hanh-dong', 'vo-thuat', 'hinh-su', 'chien-tranh', 'gay-can']))
        .take(12)
        .toList();
    final anime = _allMovies
        .where((m) =>
            _hasType(m, ['hoat_hinh', 'anime']) ||
            _hasGenre(m, ['hoat-hinh']))
        .take(12)
        .toList();

    MovieRowSection? sectionOrNull({
      required String title,
      String? subtitle,
      required IconData icon,
      required Color color,
      required List<Movie> movies,
      String? genreSlugForSeeAll,
    }) {
      if (movies.isEmpty) return null;
      int? gid;
      String? gname;
      if (genreSlugForSeeAll != null) {
        gid = _genreIdBySlug(genreSlugForSeeAll);
        if (gid != null) {
          outer:
          for (final m in _allMovies) {
            for (final g in m.genres) {
              if (g.id == gid) {
                gname = g.getName();
                break outer;
              }
            }
          }
        }
      }
      return MovieRowSection(
        title: title,
        subtitle: subtitle,
        icon: icon,
        accentColor: color,
        movies: movies,
        onSeeAll: (gid != null)
            ? () => _openSearchWithGenre(gid!, gname ?? title)
            : null,
      );
    }

    final sections = <Widget>[];
    final s1 = sectionOrNull(
        title: 'Đang thịnh hành',
        subtitle: 'Những bộ phim được xem nhiều nhất tuần qua',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF4B5C),
        movies: trending);
    final s2 = sectionOrNull(
        title: 'Phim Hàn Quốc đặc sắc',
        subtitle: 'Oppa và những chuyện tình khiến tim rung rinh',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFEC4899),
        movies: korean);
    final s3 = sectionOrNull(
        title: 'Phim Trung mãn nhãn',
        subtitle: 'Kiếm hiệp, cổ trang, tiên hiệp đẹp như tranh',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFF59E0B),
        movies: chinese);
    final s4 = sectionOrNull(
        title: 'Phim Âu Mỹ chiếu rạp',
        subtitle: 'Bom tấn Hollywood bùng nổ mãn nhãn',
        icon: Icons.movie_filter_rounded,
        color: const Color(0xFF3B82F6),
        movies: usEu);
    final s5 = sectionOrNull(
        title: 'Nơi phép thuật thức tỉnh dưới ánh trăng',
        subtitle: 'Viễn tưởng, thần thoại đưa bạn lạc vào thế giới khác',
        icon: Icons.nightlight_round,
        color: const Color(0xFF8B5CF6),
        movies: magic);
    final s6 = sectionOrNull(
        title: 'Tình cảm lãng mạn',
        subtitle: 'Yêu đương, chữa lành, ngọt ngào tan chảy',
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFFF43F5E),
        movies: romance,
        genreSlugForSeeAll: 'tinh-cam');
    final s7 = sectionOrNull(
        title: 'Hành động nghẹt thở',
        subtitle: 'Võ thuật, hình sự, rượt đuổi không khoan nhượng',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFEF4444),
        movies: action,
        genreSlugForSeeAll: 'hanh-dong');
    final s8 = sectionOrNull(
        title: 'Hoạt hình & Anime',
        subtitle: 'Doraemon, Conan và thế giới tuổi thơ trở lại',
        icon: Icons.child_care_rounded,
        color: const Color(0xFF06B6D4),
        movies: anime);
    for (final s in [s1, s2, s3, s4, s5, s6, s7, s8]) {
      if (s != null) {
        sections.add(s);
        sections.add(const SizedBox(height: 20));
      }
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchMovies,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (_heroMovies.isNotEmpty) ...[
              HeroBannerCarousel(movies: _heroMovies),
              const SizedBox(height: 20),
            ],
            ...sections,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('MỚI CẬP NHẬT',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B82F6),
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 12),
            MovieGrid(
              movies: _allMovies,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
