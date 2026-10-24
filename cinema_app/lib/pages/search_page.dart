import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/movie_model.dart';
import '../providers/theme_provider.dart';
import 'movie_detail_page.dart';

/// Trang Tìm kiếm phim (Component 2 trong ảnh mẫu).
class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({
    super.key,
    this.initialQuery,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Movie> _allMovies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = true;

  final List<String> _suggestions = [
    'Hành động',
    'Tình cảm',
    'Kinh dị',
    'Hài',
    'Hoạt hình',
    'Viễn tưởng',
  ];

  final List<String> _recentSearches = [
    'Cô dâu thượng hạng',
    'Tình yêu và định mệnh',
    'Vua trò chơi',
    'Phim Hàn Quốc',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final snap = await _firestore.collection(CollectionNames.movies).get();
      final list = snap.docs.map((d) => Movie.fromJson(d.data())).toList();

      if (mounted) {
        setState(() {
          _allMovies = list;
          _isLoading = false;
          _filterMovies(_searchController.text);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterMovies(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredMovies = [];
      });
      return;
    }

    setState(() {
      _filteredMovies = _allMovies.where((m) {
        final title = m.name.toLowerCase();
        final desc = m.description.toLowerCase();
        final type = m.type.toLowerCase();
        return title.contains(q) || desc.contains(q) || type.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back (nếu có thể pop), Logo PhimHay24h, Nút DarkMode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
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

            // Search input box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF242424) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: _filterMovies,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên phim, diễn viên...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                            onPressed: () {
                              _searchController.clear();
                              _filterMovies('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF4B5C)),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nếu có từ khoá thì hiển thị Kết quả tìm kiếm
                          if (hasQuery) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Kết quả tìm kiếm',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_filteredMovies.length} kết quả',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_filteredMovies.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'Không tìm thấy phim phù hợp',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredMovies.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, index) {
                                  final m = _filteredMovies[index];
                                  return _buildMovieResultItem(m, isDark);
                                },
                              ),
                          ] else ...[
                            // Gợi ý tìm kiếm
                            const Text(
                              'Gợi ý tìm kiếm',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _suggestions.map((s) {
                                return GestureDetector(
                                  onTap: () {
                                    _searchController.text = s;
                                    _filterMovies(s);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Tìm kiếm gần đây
                            const Text(
                              'Tìm kiếm gần đây',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._recentSearches.map((r) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _searchController.text = r;
                                          _filterMovies(r);
                                        },
                                        child: Text(
                                          r,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: isDark ? Colors.white70 : const Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _recentSearches.remove(r);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieResultItem(Movie m, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MovieDetailPage(movie: m)),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 68,
              color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
              child: m.posterUrl != null && m.posterUrl!.isNotEmpty && m.posterUrl != '{}'
                  ? Image.network(
                      m.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.movie_outlined, size: 24, color: Colors.grey),
                    )
                  : const Icon(Icons.movie_outlined, size: 24, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
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
                  '${m.totalEpisodes > 0 ? 'Tập ${m.totalEpisodes}' : 'Phim lẻ'} · ${m.releaseYear ?? 2026} · ${m.getTypeLabel()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }
}
