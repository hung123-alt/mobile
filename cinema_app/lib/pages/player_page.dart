import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../providers/auth_provider.dart';
import '../providers/watch_history_provider.dart';
import '../services/api_service.dart';
import '../services/rating_service.dart';
import '../widgets/app_top_navbar.dart';
import '../widgets/comment_section.dart';
import '../widgets/embed_video_player.dart';
import '../widgets/episode_grid.dart';
import '../widgets/error_report_modal.dart';
import '../widgets/movie_share_helper.dart';
import '../widgets/rating_modal.dart';

/// Trang xem phim (Player) - có dùng chung `AppTopNavbar`, phát trực tiếp từ `embedUrl`,
/// tự động lưu lịch sử xem và hiển thị khu vực Bình luận ở bên dưới.
///
/// Đã bổ sung 2 nút **Đánh giá phim** + **Báo lỗi phim** (giống trang chi tiết)
/// và nút **Chia sẻ** chuẩn (dùng chung [MovieShareHelper]).
class PlayerPage extends StatefulWidget {
  final Movie movie;
  final int initialEpisode;
  final Episode? selectedEpisode;
  final List<Episode>? episodes;

  const PlayerPage({
    super.key,
    required this.movie,
    this.initialEpisode = 1,
    this.selectedEpisode,
    this.episodes,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static const Color primaryColor = Color(0xFFFF4B5C);

  List<Episode> _episodes = [];
  Episode? _currentEpisode;
  bool _isLoadingEpisodes = true;

  final ApiService _apiService = ApiService();
  final RatingService _ratingService = RatingService();
  int? _myScore;

  @override
  void initState() {
    super.initState();
    _initEpisodes();
    _loadMyRating();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _initEpisodes() async {
    if (widget.episodes != null && widget.episodes!.isNotEmpty) {
      _episodes = widget.episodes!;
      _currentEpisode = widget.selectedEpisode ??
          _episodes.firstWhere(
            (e) => e.episodeNumber == widget.initialEpisode,
            orElse: () => _episodes.first,
          );
      setState(() => _isLoadingEpisodes = false);
      _recordCurrentWatch();
      return;
    }

    final fetched = await EpisodeGrid.fetchEpisodesForMovie(widget.movie.id);
    if (!mounted) return;

    Episode? chosen = widget.selectedEpisode;
    if (chosen == null && fetched.isNotEmpty) {
      chosen = fetched.firstWhere(
        (e) => e.episodeNumber == widget.initialEpisode,
        orElse: () => fetched.first,
      );
    }

    setState(() {
      _episodes = fetched;
      _currentEpisode = chosen;
      _isLoadingEpisodes = false;
    });

    _recordCurrentWatch();
  }

  Future<void> _loadMyRating() async {
    try {
      final score = await _ratingService.getMyScore(widget.movie);
      if (!mounted) return;
      setState(() => _myScore = score);
    } catch (_) {}
  }

  void _recordCurrentWatch() {
    WatchHistoryProvider.instance.recordWatch(
      movie: widget.movie,
      episode: _currentEpisode,
      fallbackEpisodeNumber: widget.initialEpisode,
    );
  }

  String get _currentEpisodeLabel {
    if (_currentEpisode != null) {
      return _currentEpisode!.getEpisodeLabel();
    }
    return 'Tập ${widget.initialEpisode}';
  }

  // ===== MỞ MODAL ĐÁNH GIÁ (giống trang chi tiết) =====
  Future<void> _openRatingModal() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn cần đăng nhập bằng Firebase Authentication để đánh giá phim.',
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
            setState(() => _myScore = score);
          },
        );
      },
    );

    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đánh giá đã được lưu vào Firebase!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ===== GỬI BÁO LỖI (giống trang chi tiết) =====
  Future<void> _submitErrorReport(
    int? episodeId,
    String errorType,
    String description,
  ) async {
    final user = AuthProvider.instance.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập trước khi báo lỗi.');
    }
    final cleanDescription = description.trim();
    if (cleanDescription.isEmpty) {
      throw ArgumentError('Vui lòng nhập mô tả lỗi.');
    }

    final token = _apiService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      await _apiService.postVoid(
        '/error-reports',
        {
          'movieId': widget.movie.id,
          'episodeId': episodeId,
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
      'movieTitle': widget.movie.name,
      'movie_title': widget.movie.name,
      'userId': user.id,
      'user_id': user.id,
      'userEmail': user.email,
      'user_email': user.email,
      'userName': user.username,
      'episodeId': episodeId,
      'episode_id': episodeId,
      'currentEpisode': _currentEpisode?.episodeNumber ?? widget.initialEpisode,
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

  Future<void> _openErrorReportModal() async {
    if (!AuthProvider.instance.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để báo lỗi phim.')),
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
        content: Text('Đã gửi báo lỗi thành công! Admin sẽ sớm xử lý.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUrl = _currentEpisode?.embedUrl.trim() ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 1. NAVBAR DÙNG CHUNG =====
            const AppTopNavbar(showBackIfCanPop: true),

            // ===== 2. KHUNG PLAYER VIDEO NHÚNG (EMBED URL) =====
            Container(
              width: double.infinity,
              height: 225,
              color: Colors.black,
              child: _isLoadingEpisodes
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4B5C),
                      ),
                    )
                  : currentUrl.isNotEmpty
                      ? EmbedVideoPlayer(embedUrl: currentUrl)
                      : _buildEmptyPlayerState(),
            ),

            // ===== 3. NỘI DUNG CUỘN =====
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên phim & trạng thái tập đang phát
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.movie.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0B1021),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.movie.getTypeLabel()} · ${widget.movie.releaseYear ?? 2026} · Đang phát $_currentEpisodeLabel',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Nút chia sẻ chuẩn
                        IconButton(
                          tooltip: 'Chia sẻ phim',
                          onPressed: () => MovieShareHelper.showShareSheet(
                            context,
                            widget.movie,
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF262626)
                                  : const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share_outlined,
                              size: 19,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== 2 NÚT ĐÁNH GIÁ + BÁO LỖI (giống trang chi tiết) =====
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _openRatingModal,
                              icon: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB400),
                                size: 20,
                              ),
                              label: Text(
                                _myScore == null
                                    ? 'Đánh giá'
                                    : 'Đã đánh giá: $_myScore/10',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _openErrorReportModal,
                              icon: const Icon(
                                Icons.report_problem_outlined,
                                size: 19,
                              ),
                              label: const Text(
                                'Báo lỗi',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF59E0B),
                                side: const BorderSide(
                                  color: Color(0xFFF59E0B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phần chọn Tập phim
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tập phim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : const Color(0xFF0B1021),
                          ),
                        ),
                        if (_episodes.isNotEmpty)
                          Text(
                            '${_episodes.length} tập',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    EpisodeGrid(
                      episodes: _episodes,
                      isLoading: _isLoadingEpisodes,
                      selectedEpisode: _currentEpisode,
                      onEpisodeTap: (ep) {
                        setState(() {
                          _currentEpisode = ep;
                        });
                        _recordCurrentWatch();
                      },
                    ),
                    const SizedBox(height: 20),

                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFE5E7EB),
                    ),
                    const SizedBox(height: 18),

                    // ===== 4. KHU VỰC BÌNH LUẬN =====
                    CommentSection(movieId: widget.movie.id),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlayerState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.movie.displayImageUrl != null)
          Opacity(
            opacity: 0.35,
            child: Image.network(
              widget.movie.displayImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                color: Colors.white70,
                size: 46,
              ),
              SizedBox(height: 10),
              Text(
                'Đang cập nhật nguồn phát cho phim này',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
