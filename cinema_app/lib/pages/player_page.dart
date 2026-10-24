import 'package:flutter/material.dart';

import '../models/movie_model.dart';

/// Trang xem phim (Player) - thiết kế chuẩn theo mẫu Component 7 trong ảnh.
class PlayerPage extends StatefulWidget {
  final Movie movie;
  final int initialEpisode;

  const PlayerPage({
    super.key,
    required this.movie,
    this.initialEpisode = 1,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late int _selectedEpisode;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _selectedEpisode = widget.initialEpisode;
  }

  int get _totalEpisodes =>
      widget.movie.totalEpisodes > 0 ? widget.movie.totalEpisodes : 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 1. KHUNG PLAYER VIDEO ĐEN =====
            Container(
              width: double.infinity,
              height: 240,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hình nền poster / banner cho player
                  if (widget.movie.bannerUrl != null &&
                      widget.movie.bannerUrl!.isNotEmpty &&
                      widget.movie.bannerUrl != '{}')
                    Opacity(
                      opacity: 0.65,
                      child: Image.network(
                        widget.movie.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackPlayerBg(),
                      ),
                    )
                  else if (widget.movie.posterUrl != null &&
                      widget.movie.posterUrl!.isNotEmpty &&
                      widget.movie.posterUrl != '{}')
                    Opacity(
                      opacity: 0.65,
                      child: Image.network(
                        widget.movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackPlayerBg(),
                      ),
                    )
                  else
                    _buildFallbackPlayerBg(),

                  // Thanh tiêu đề player trên cùng
                  Positioned(
                    top: 10,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            '${widget.movie.name} - Tập $_selectedEpisode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cast_rounded, color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Nút play/pause giữa màn hình
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isPlaying = !_isPlaying);
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                  // Thanh tiến trình và nút điều khiển đáy player
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thanh Slider tiến trình
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            trackHeight: 2.5,
                            activeTrackColor: const Color(0xFFFF4B5C),
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                            thumbColor: const Color(0xFFFF4B5C),
                          ),
                          child: Slider(
                            value: 0.28,
                            onChanged: (v) {},
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isPlaying = !_isPlaying),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '12:34 / 45:20',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            const Spacer(),
                            const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                            const SizedBox(width: 12),
                            const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== 2. DANH SÁCH TẬP PHIM =====
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tập phim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Lưới các nút chọn tập [1], [2], [3]...
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_totalEpisodes, (index) {
                        final epNumber = index + 1;
                        final isSelected = epNumber == _selectedEpisode;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedEpisode = epNumber);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF4B5C)
                                  : (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF4B5C).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$epNumber',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF374151)),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }),
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
                      '${widget.movie.getTypeLabel()} · ${widget.movie.releaseYear ?? 2026} · Đang phát tập $_selectedEpisode',
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

  Widget _buildFallbackPlayerBg() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(Icons.movie_rounded, color: Colors.white24, size: 64),
      ),
    );
  }
}
