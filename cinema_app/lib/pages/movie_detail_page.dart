
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../providers/auth_provider.dart';
import '../providers/watchlist_provider.dart';
import '../services/api_service.dart';
import '../services/movie_service.dart';
import '../services/rating_service.dart';
import '../widgets/episode_grid.dart';
import '../widgets/error_report_modal.dart';
import '../widgets/movie_card.dart';
import '../widgets/rating_modal.dart';
import 'player_page.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailPage({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailPage> createState() =>
      _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  static const Color primaryColor = Color(0xFFFF4B5C);

  final WatchlistProvider _watchlist =
      WatchlistProvider.instance;

  final ApiService _apiService = ApiService();
  final RatingService _ratingService = RatingService();

  late final Stream<RatingStats> _ratingStatsStream;

  int? _myScore;

  List<Episode> _episodes = [];
  bool _isLoadingEpisodes = true;

  List<Movie> _relatedMovies = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();

    _ratingStatsStream =
        _ratingService.watchStats(widget.movie);

    _loadMyRating();
    _loadEpisodes();
    _loadRelatedMovies();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // ===== LẤY ĐÁNH GIÁ CỦA NGƯỜI DÙNG =====
  Future<void> _loadMyRating() async {
    try {
      final score =
          await _ratingService.getMyScore(widget.movie);

      if (!mounted) return;

      setState(() {
        _myScore = score;
      });
    } catch (error) {
      debugPrint('Không tải được điểm cá nhân: $error');
    }
  }

  // ===== TẢI TẬP PHIM =====
  Future<void> _loadEpisodes() async {
    try {
      final episodes =
          await EpisodeGrid.fetchEpisodesForMovie(
        widget.movie.id,
      );

      if (!mounted) return;

      setState(() {
        _episodes = episodes;
      });
    } catch (error) {
      debugPrint('Không tải được tập phim: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEpisodes = false;
        });
      }
    }
  }

  // ===== TẢI PHIM LIÊN QUAN =====
  Future<void> _loadRelatedMovies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(CollectionNames.movies)
          .get();

      final currentGenreIds = widget.movie.genres
          .map((genre) => genre.id)
          .toSet();

      final movies = <Movie>[];

      for (final document in snapshot.docs) {
        try {
          final movie = Movie.fromJson(document.data());

          if (!movie.isVisible) continue;
          if (movie.id == widget.movie.id) continue;
          if (movie.slug == widget.movie.slug) continue;

          movies.add(movie);
        } catch (error) {
          debugPrint(
            'Không đọc được phim ${document.id}: $error',
          );
        }
      }

      int commonGenres(Movie movie) {
        return movie.genres
            .where(
              (genre) =>
                  currentGenreIds.contains(genre.id),
            )
            .length;
      }

      movies.sort((a, b) {
        final byGenre = commonGenres(b)
            .compareTo(commonGenres(a));

        if (byGenre != 0) return byGenre;

        final aType =
            a.type == widget.movie.type ? 1 : 0;

        final bType =
            b.type == widget.movie.type ? 1 : 0;

        if (aType != bType) {
          return bType.compareTo(aType);
        }

        return b.viewCount.compareTo(a.viewCount);
      });

      final suggested = movies
          .where(
            (movie) =>
                commonGenres(movie) > 0 ||
                movie.type == widget.movie.type,
          )
          .take(10)
          .toList();

      if (!mounted) return;

      setState(() {
        _relatedMovies = suggested;
        _isLoadingRelated = false;
      });
    } catch (error) {
      debugPrint(
        'Không tải được phim liên quan từ Firebase: $error',
      );
    }

    // Ưu tiên kết quả gợi ý từ Backend REST API nếu còn khả dụng.
    try {
      final detail = await MovieService(_apiService)
          .getDetail(widget.movie.slug)
          .timeout(const Duration(seconds: 5));

      final seenIds = <int>{};

      final apiMovies = detail.relatedMovies
          .where(
            (movie) =>
                movie.isVisible &&
                movie.id != widget.movie.id &&
                movie.slug != widget.movie.slug &&
                seenIds.add(movie.id),
          )
          .take(10)
          .toList();

      if (!mounted) return;

      if (apiMovies.isNotEmpty) {
        setState(() {
          _relatedMovies = apiMovies;
        });
      }
    } catch (error) {
      debugPrint(
        'API phim liên quan không khả dụng: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
      }
    }
  }

  // ===== MỞ TRANG XEM PHIM =====
  void _openPlayer({Episode? episode}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPage(
          movie: widget.movie,
          episodes:
              _episodes.isNotEmpty ? _episodes : null,
          selectedEpisode: episode ??
              (_episodes.isNotEmpty
                  ? _episodes.first
                  : null),
          initialEpisode:
              episode?.episodeNumber ?? 1,
        ),
      ),
    );
  }

  // ===== MỞ MODAL ĐÁNH GIÁ =====
  Future<void> _openRatingModal() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn cần đăng nhập bằng Firebase Authentication '
            'để đánh giá phim.',
          ),
        ),
      );
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return RatingModal(
          movieTitle: widget.movie.name,
          initialScore: _myScore,
          onSubmit: (score, content) async {
            await _ratingService.rate(
              movie: widget.movie,
              score: score,
              content: content,
            );

            if (!mounted) return;

            setState(() {
              _myScore = score;
            });
          },
        );
      },
    );

    if (!mounted || submitted != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đánh giá đã được lưu vào Firebase!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ===== GỬI BÁO LỖI =====
  Future<void> _submitErrorReport(
    int? episodeId,
    String errorType,
    String description,
  ) async {
    final user = AuthProvider.instance.currentUser;

    if (user == null) {
      throw StateError(
        'Bạn cần đăng nhập trước khi báo lỗi.',
      );
    }

    final cleanDescription = description.trim();

    if (cleanDescription.isEmpty) {
      throw ArgumentError(
        'Vui lòng nhập mô tả lỗi.',
      );
    }

    final token = _apiService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      await _apiService.postVoid(
        '/error-reports',
        {
          'movieId': widget.movie.id,
          'episodeId': ?episodeId,
          'errorType': errorType,
          'description': cleanDescription,
        },
      );
      return;
    }

    final now = DateTime.now().toIso8601String();

    await FirebaseFirestore.instance
        .collection(CollectionNames.errorReports)
        .add({
      'movieId': widget.movie.id,
      'movie_id': widget.movie.id,
      'userId': user.id,
      'user_id': user.id,
      'episodeId': episodeId,
      'episode_id': episodeId,
      'errorType': errorType,
      'error_type': errorType,
      'description': cleanDescription,
      'status': 'pending',
      'adminNote': null,
      'admin_note': null,
      'createdAt': FieldValue.serverTimestamp(),
      'created_at': now,
    });
  }

  // ===== MỞ MODAL BÁO LỖI =====
  Future<void> _openErrorReportModal() async {
    if (!AuthProvider.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng đăng nhập để báo lỗi phim.',
          ),
        ),
      );
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ErrorReportModal(
          movieName: widget.movie.name,
          episodes: _episodes,
          onSubmit: _submitErrorReport,
        );
      },
    );

    if (!mounted || submitted != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã gửi báo lỗi thành công!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ===== THỐNG KÊ ĐÁNH GIÁ FIREBASE =====
  Widget _buildRatingSummary() {
    return StreamBuilder<RatingStats>(
      stream: _ratingStatsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Không thể tải đánh giá',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Text(
            'Đang tải đánh giá...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          );
        }

        final stats = snapshot.data!;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 17,
              color: Color(0xFFFFB400),
            ),
            const SizedBox(width: 4),
            Text(
              stats.count == 0
                  ? 'Chưa có đánh giá'
                  : '${stats.average.toStringAsFixed(1)}/10 '
                      '(${stats.count} lượt)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  // ===== PHIM LIÊN QUAN =====
  Widget _buildRelatedMovies() {
    if (_isLoadingRelated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    if (_relatedMovies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Hiện chưa có phim liên quan.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      );
    }

    return SizedBox(
      height: 245,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _relatedMovies.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = _relatedMovies[index];

          return SizedBox(
            width: 145,
            child: MovieCard(
              movie: movie,
              width: 145,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MovieDetailPage(movie: movie),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===== GIAO DIỆN CHI TIẾT PHIM =====
  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final bannerImg = movie.displayImageUrl;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===== BANNER =====
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.45,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.45,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã sao chép liên kết: ${movie.name}',
                      ),
                    ),
                  );
                },
              ),
              ListenableBuilder(
                listenable: _watchlist,
                builder: (context, _) {
                  final isFav =
                      _watchlist.isFavorite(movie.id);

                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.45,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: isFav
                            ? primaryColor
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      _watchlist.toggleFavorite(movie);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav
                                ? 'Đã xóa khỏi danh sách yêu thích'
                                : 'Đã thêm vào danh sách yêu thích',
                          ),
                          duration: const Duration(
                            seconds: 1,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerImg != null &&
                      bannerImg.isNotEmpty &&
                      bannerImg != '{}')
                    Image.network(
                      bannerImg,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildFallbackBanner(),
                    )
                  else
                    _buildFallbackBanner(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark
                                ? const Color(0xFF121212)
                                : Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== NỘI DUNG CHI TIẾT =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Tên phim
                  Text(
                    movie.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Thông tin + điểm đánh giá
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment:
                        WrapCrossAlignment.center,
                    children: [
                      Text(
                        _buildMetaString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      _buildRatingSummary(),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Nút Xem ngay và Bookmark
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            label: const Text(
                              'Xem ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            onPressed: () =>
                                _openPlayer(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ListenableBuilder(
                        listenable: _watchlist,
                        builder: (context, _) {
                          final isFav =
                              _watchlist.isFavorite(
                            movie.id,
                          );

                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFF262626,
                                    )
                                  : const Color(
                                      0xFFF3F4F6,
                                    ),
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: isFav
                                    ? primaryColor
                                    : const Color(
                                        0xFF4B5563,
                                      ),
                                size: 22,
                              ),
                              onPressed: () =>
                                  _watchlist.toggleFavorite(
                                movie,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Nút Đánh giá
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _openRatingModal,
                      icon: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB400),
                      ),
                      label: Text(
                        _myScore == null
                            ? 'Đánh giá phim'
                            : 'Đã đánh giá: $_myScore/10',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(
                          color: primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Nút Báo lỗi
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _openErrorReportModal,
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        size: 20,
                      ),
                      label: const Text(
                        'Báo lỗi phim',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFFF59E0B),
                        side: const BorderSide(
                          color: Color(0xFFF59E0B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mô tả
                  const Text(
                    'Nội dung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.description.isNotEmpty
                        ? movie.description
                        : 'Chưa có nội dung mô tả phim.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Danh sách tập phim
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tập phim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isLoadingEpisodes &&
                          _episodes.isNotEmpty)
                        Text(
                          '${_episodes.length} tập hiện có',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  EpisodeGrid(
                    episodes: _episodes,
                    isLoading: _isLoadingEpisodes,
                    onEpisodeTap: (episode) =>
                        _openPlayer(episode: episode),
                  ),

                  const SizedBox(height: 30),

                  // Danh sách phim liên quan
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Phim liên quan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_relatedMovies.isNotEmpty)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Vuốt để xem',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildRelatedMovies(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildMetaString() {
    final type = widget.movie.getTypeLabel();

    final episodeCount = _episodes.isNotEmpty
        ? _episodes.length
        : widget.movie.totalEpisodes;

    final episodes = episodeCount > 0
        ? '$episodeCount tập'
        : 'Phim lẻ';

    final year =
        widget.movie.releaseYear?.toString() ??
            'Chưa rõ năm';

    return '$type · $episodes · $year';
  }

  Widget _buildFallbackBanner() {
    return Container(
      color: const Color(0xFF1F2937),
      child: const Center(
        child: Icon(
          Icons.movie_filter_rounded,
          size: 64,
          color: Colors.white24,
        ),
      ),
    );
  }
}
