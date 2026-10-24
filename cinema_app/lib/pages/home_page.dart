import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/movie_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/movie_grid.dart';
import '../widgets/trending_carousel.dart';
import 'search_page.dart';

/// Trang chủ (Trang 1 trong ảnh mẫu)
///
/// Tải dữ liệu phim thực tế từ Firebase Cloud Firestore (collection `movies`).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMoviesFromFirebase();
  }

  Future<void> _fetchMoviesFromFirebase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _firestore.collection(CollectionNames.movies).get();

      final List<Movie> loaded = [];
      for (final doc in snapshot.docs) {
        try {
          final m = Movie.fromJson(doc.data());
          if (m.isVisible) {
            loaded.add(m);
          }
        } catch (e) {
          debugPrint('Error parsing movie doc ${doc.id}: $e');
        }
      }

      // Sắp xếp phim nổi bật (isFeatured = true hoặc lượt xem cao nhất)
      final trending = loaded.where((m) => m.isFeatured).toList();
      if (trending.isEmpty) {
        trending.addAll(loaded.take(10));
      }

      setState(() {
        _allMovies = loaded;
        _trendingMovies = trending;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching movies: $e');
      setState(() {
        _errorMessage = 'Không thể tải danh sách phim từ Firebase: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // ===== 1. APP BAR TÙY BIẾN THEO MOCKUP =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Nút Menu bên trái
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menu PhimHay24h'),
                          duration: Duration(milliseconds: 900),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),

                  // Logo: "PhimHay" (đen) + "24h" (đỏ #FF4B5C)
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'PhimHay',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '24h',
                          style: TextStyle(
                            color: Color(0xFFFF4B5C),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Nút chuyển chế độ Sáng / Tối (Icon trăng)
                  ListenableBuilder(
                    listenable: ThemeProvider.instance,
                    builder: (context, _) {
                      final isDarkMode = ThemeProvider.instance.isDarkMode;
                      return IconButton(
                        icon: Icon(
                          isDarkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: isDark ? Colors.amber : const Color(0xFF4B5563),
                          size: 22,
                        ),
                        onPressed: () => ThemeProvider.instance.toggleTheme(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ===== 2. THANH TÌM KIẾM (Search Pill) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242424) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.grey[400] : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : const Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ===== 3. NỘI DUNG CHÍNH (Trending Carousel + Mới Cập Nhật Grid) =====
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4B5C),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4B5C),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _fetchMoviesFromFirebase,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFFF4B5C),
                          onRefresh: _fetchMoviesFromFirebase,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SECTION 1: ĐANG THỊNH HÀNH (Carousel)
                                TrendingCarousel(movies: _trendingMovies),
                                const SizedBox(height: 20),

                                // SECTION 2: MỚI CẬP NHẬT (Header xanh dương)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'MỚI CẬP NHẬT',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF3B82F6), // Màu xanh theo mockup
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Lưới phim 3 cột hiển thị toàn bộ data từ Firebase
                                MovieGrid(
                                  movies: _allMovies,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
