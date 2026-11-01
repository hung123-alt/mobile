
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/movie_model.dart';
import '../routes/app_routes.dart';
import '../widgets/app_top_navbar.dart';
import '../widgets/movie_grid.dart';
import '../widgets/trending_carousel.dart';
import 'search_page.dart';

/// Trang chủ PhimHay24h.
/// Hiển thị phim thịnh hành, phim mới cập nhật
/// và điều hướng tới trang phim ngẫu nhiên.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFFFF4B5C);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMoviesFromFirebase();
  }

  // =====================================================
  // 1. TẢI DANH SÁCH PHIM TỪ FIREBASE
  // =====================================================
  Future<void> _fetchMoviesFromFirebase() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _firestore
          .collection(CollectionNames.movies)
          .get();

      final List<Movie> loaded = [];

      for (final doc in snapshot.docs) {
        try {
          final movie = Movie.fromJson(doc.data());

          // Chỉ hiển thị phim đang được công khai
          if (movie.isVisible) {
            loaded.add(movie);
          }
        } catch (error) {
          debugPrint(
            'Lỗi đọc dữ liệu phim ${doc.id}: $error',
          );
        }
      }

      // Phim nổi bật
      final trending = loaded
          .where((movie) => movie.isFeatured)
          .toList();

      // Nếu không có phim nổi bật,
      // lấy 10 phim có nhiều lượt xem nhất.
      if (trending.isEmpty) {
        final sorted = List<Movie>.from(loaded);

        sorted.sort(
          (a, b) => b.viewCount.compareTo(a.viewCount),
        );

        trending.addAll(sorted.take(10));
      }

      if (!mounted) return;

      setState(() {
        _allMovies = loaded;
        _trendingMovies = trending;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Lỗi tải danh sách phim Firebase: $error',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Không thể tải danh sách phim từ Firebase.\n'
            'Vui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // 2. ĐIỀU HƯỚNG
  // =====================================================

  // Mở trang tìm kiếm
  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchPage(),
      ),
    );
  }

  // Mở trang phim ngẫu nhiên
  void _openRandomPage() {
    Navigator.pushNamed(
      context,
      AppRoutes.random,
    );
  }

  // =====================================================
  // 3. THANH TÌM KIẾM
  // =====================================================
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: GestureDetector(
        onTap: _openSearchPage,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF242424)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF333333)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: isDark
                    ? Colors.grey[400]
                    : const Color(0xFF9CA3AF),
                size: 20,
              ),

              const SizedBox(width: 8),

              Text(
                'Search',
                style: TextStyle(
                  color: isDark
                      ? Colors.grey[400]
                      : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 4. NÚT PHIM NGẪU NHIÊN
  // =====================================================
  Widget _buildRandomButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          onPressed: _openRandomPage,

          icon: const Icon(
            Icons.shuffle_rounded,
            color: primaryColor,
            size: 21,
          ),

          label: const Text(
            'Phim ngẫu nhiên',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),

          style: OutlinedButton.styleFrom(
            backgroundColor: isDark
                ? const Color(0xFF241C20)
                : const Color(0xFFFFF3F4),

            side: const BorderSide(
              color: primaryColor,
              width: 1,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 5. TIÊU ĐỀ DANH SÁCH PHIM
  // =====================================================
  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'MỚI CẬP NHẬT',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3B82F6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // =====================================================
  // 6. GIAO DIỆN KHI TẢI DỮ LIỆU
  // =====================================================
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  // =====================================================
  // 7. GIAO DIỆN KHI CÓ LỖI
  // =====================================================
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              _errorMessage ?? 'Đã xảy ra lỗi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _fetchMoviesFromFirebase,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 8. GIAO DIỆN KHI CHƯA CÓ PHIM
  // =====================================================
  Widget _buildEmptyMovies() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.movie_outlined,
              color: Colors.grey,
              size: 48,
            ),

            SizedBox(height: 12),

            Text(
              'Chưa có phim nào được cập nhật',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 9. NỘI DUNG TRANG CHỦ
  // =====================================================
  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchMoviesFromFirebase,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phim đang thịnh hành
            if (_trendingMovies.isNotEmpty) ...[
              TrendingCarousel(
                movies: _trendingMovies,
              ),
              const SizedBox(height: 20),
            ],

            // Tiêu đề phim mới cập nhật
            _buildSectionTitle(),

            const SizedBox(height: 12),

            // Lưới danh sách phim
            if (_allMovies.isNotEmpty)
              MovieGrid(
                movies: _allMovies,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
              )
            else
              _buildEmptyMovies(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 10. GIAO DIỆN CHÍNH
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAFA),

      body: SafeArea(
        child: Column(
          children: [
            // ===== NAVBAR =====
            const AppTopNavbar(),

            // ===== THANH TÌM KIẾM =====
            _buildSearchBar(isDark),

            // ===== NÚT PHIM NGẪU NHIÊN =====
            _buildRandomButton(isDark),

            const SizedBox(height: 10),

            // ===== NỘI DUNG =====
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _errorMessage != null
                      ? _buildError()
                      : _buildHomeContent(),
            ),
          ],
        ),
      ),
    );
  }
}
