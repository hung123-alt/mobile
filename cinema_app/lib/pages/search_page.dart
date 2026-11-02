import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../services/firestore_movie_service.dart';
import '../widgets/app_top_navbar.dart';
import 'movie_detail_page.dart';

/// Trang Tìm kiếm phim — đã fix lỗi rớt phim.
///
/// - Dùng [FirestoreMovieService.fetchEnrichedMovies] nên phim nào cũng có
///   đủ `genres`/`countries` từ bảng trung gian `movie_genres`/`movie_countries`.
/// - Tìm theo tên + mô tả + thể loại + quốc gia (trước đây chỉ tìm tên/mô tả
///   nên gõ "Hành động" chỉ ra 3 phim).
/// - Hỗ trợ lọc sẵn theo thể loại khi mở từ trang Thể loại
///   ([initialGenreId]/[initialGenreName]).
class SearchPage extends StatefulWidget {
  final String? initialQuery;
  final int? initialGenreId;
  final String? initialGenreName;

  const SearchPage({
    super.key,
    this.initialQuery,
    this.initialGenreId,
    this.initialGenreName,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _allMovies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = true;

  int? _activeGenreId;
  String? _activeGenreName;

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
    _activeGenreId = widget.initialGenreId;
    _activeGenreName = widget.initialGenreName;
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final list = await FirestoreMovieService.fetchEnrichedMovies();

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

  String _noAccent(String s) {
    var str = s.toLowerCase().trim();
    const map = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    map.forEach((k, v) => str = str.replaceAll(k, v));
    return str;
  }

  void _filterMovies(String query) {
    final q = _noAccent(query.trim());
    final genreId = _activeGenreId;

    setState(() {
      _filteredMovies = _allMovies.where((m) {
        // Lọc thể loại trước (từ trang Category sang)
        if (genreId != null && genreId > 0) {
          if (!m.genres.any((g) => g.id == genreId)) return false;
        }
        if (q.isEmpty) return genreId != null && genreId > 0;
        final title = _noAccent(m.name);
        final desc = _noAccent(m.description);
        final type = _noAccent('${m.type} ${m.getTypeLabel()}');
        final genreText =
            _noAccent(m.genres.map((g) => '${g.getName()} ${g.slug}').join(' '));
        final countryText = _noAccent(
            m.countries.map((c) => '${c.getName()} ${c.slug}').join(' '));
        return title.contains(q) ||
            desc.contains(q) ||
            type.contains(q) ||
            genreText.contains(q) ||
            countryText.contains(q);
      }).toList();
    });
  }

  void _clearGenreFilter() {
    setState(() {
      _activeGenreId = null;
      _activeGenreName = null;
    });
    _filterMovies(_searchController.text);
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
    final hasGenreFilter = _activeGenreId != null && _activeGenreId! > 0;
    final showResult = hasQuery || hasGenreFilter;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back (nếu có thể pop), Logo PhimHay24h ở giữa, Nút DarkMode
            const AppTopNavbar(showBackIfCanPop: true),

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
                    hintText: 'Nhập tên phim, thể loại, quốc gia...',
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

            // Chip lọc thể loại (khi mở từ trang Thể loại)
            if (hasGenreFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B5C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF4B5C).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_outlined,
                              size: 14, color: Color(0xFFFF4B5C)),
                          const SizedBox(width: 6),
                          Text(
                            _activeGenreName ?? 'Thể loại #$_activeGenreId',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF4B5C),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _clearGenreFilter,
                            child: const Icon(Icons.close_rounded,
                                size: 15, color: Color(0xFFFF4B5C)),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          // Nếu có từ khoá / filter thì hiển thị Kết quả tìm kiếm
                          if (showResult) ...[
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
                                  '${_filteredMovies.length} kết quả / ${_allMovies.length} phim',
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
    final genreLabel = m.genres.isEmpty
        ? m.getTypeLabel()
        : m.genres.take(2).map((g) => g.getName()).join(' · ');
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
              child: m.displayImageUrl != null
                  ? Image.network(
                      m.displayImageUrl!,
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
                  '${m.totalEpisodes > 0 ? 'Tập ${m.totalEpisodes}' : 'Phim lẻ'} · ${m.releaseYear ?? '—'} · $genreLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
