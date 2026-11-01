import 'package:flutter/material.dart';

import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../providers/watch_history_provider.dart';
import '../widgets/app_top_navbar.dart';
import '../widgets/comment_section.dart';
import '../widgets/embed_video_player.dart';
import '../widgets/episode_grid.dart';

/// Trang xem phim (Player) - có dùng chung `AppTopNavbar`, phát trực tiếp từ `embedUrl`,
/// tự động lưu lịch sử xem và hiển thị khu vực Bình luận ở bên dưới.
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
  List<Episode> _episodes = [];
  Episode? _currentEpisode;
  bool _isLoadingEpisodes = true;

  @override
  void initState() {
    super.initState();
    _initEpisodes();
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

            // ===== 3. NỘI DUNG CUỘN: THÔNG TIN PHIM + TẬP PHIM + BÌNH LUẬN =====
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên phim & trạng thái tập đang phát
                    Text(
                      widget.movie.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0B1021),
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
