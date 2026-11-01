import 'package:flutter/material.dart';

import '../models/episode_model.dart';
import '../models/movie_model.dart';
import '../widgets/embed_video_player.dart';
import '../widgets/episode_grid.dart';

/// Trang xem phim (Player) - phát trực tiếp từ `embedUrl` của tập phim trong Firestore.
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
          isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 1. THANH TIÊU ĐỀ TRÊN CÙNG CỦA TRANG XEM PHIM =====
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.movie.name} - $_currentEpisodeLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_currentEpisode != null &&
                      _currentEpisode!.serverName.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B5C).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF4B5C).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        _currentEpisode!.serverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ===== 2. KHUNG PLAYER VIDEO NHÚNG (EMBED URL) =====
            Container(
              width: double.infinity,
              height: 230,
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

            // ===== 3. DANH SÁCH TẬP PHIM & THÔNG TIN PHIM =====
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tập phim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 14),

                    // Lưới chọn tập phim thực tế từ Firestore
                    EpisodeGrid(
                      episodes: _episodes,
                      isLoading: _isLoadingEpisodes,
                      selectedEpisode: _currentEpisode,
                      onEpisodeTap: (ep) {
                        setState(() {
                          _currentEpisode = ep;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Thông tin tóm tắt phim bên dưới
                    Text(
                      widget.movie.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.movie.getTypeLabel()} · ${widget.movie.releaseYear ?? 2026} · Đang phát $_currentEpisodeLabel',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.movie.description.isNotEmpty
                          ? widget.movie.description
                          : 'Bộ phim hấp dẫn được phát sóng độc quyền trên PhimHay24h.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
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
