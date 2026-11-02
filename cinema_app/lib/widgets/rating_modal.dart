
import 'package:flutter/material.dart';
import 'rating_stars.dart';

class RatingModal extends StatefulWidget {
  final String movieTitle;
  final int? initialScore;

  // Hàm gửi đánh giá do trang chi tiết phim cung cấp.
  final Future<void> Function(int score, String? content) onSubmit;

  const RatingModal({
    super.key,
    required this.movieTitle,
    required this.onSubmit,
    this.initialScore,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  final TextEditingController _commentController =
      TextEditingController();

  int _selectedScore = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _selectedScore =
        (widget.initialScore ?? 0).clamp(0, 10).toInt();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedScore < 1 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final content = _commentController.text.trim();

      await widget.onSubmit(
        _selectedScore,
        content.isEmpty ? null : content,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is StateError && e.message.contains('Hãy đăng nhập') ? 'Hãy đăng nhập để đánh giá' : 'Không thể gửi đánh giá: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề Modal
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Đánh giá phim',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  widget.movieTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFFF4B5C),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // Hiển thị điểm đang chọn
                Center(
                  child: Text(
                    '$_selectedScore/10',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4B5C),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Widget đánh giá sao
                Center(
                  child: RatingStars(
                    score: _selectedScore.toDouble(),
                    readOnly: false,
                    size: 38,
                    spacing: 6,
                    onChanged: (score) {
                      setState(() {
                        _selectedScore = score;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    'Chọn từ 1 đến 10 điểm',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Nhận xét
                const Text(
                  'Nhận xét của bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText:
                        'Chia sẻ cảm nhận của bạn về bộ phim...',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF292929)
                        : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút gửi đánh giá
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _selectedScore == 0 ||
                            _isSubmitting
                        ? null
                        : _submitRating,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSubmitting
                          ? 'Đang gửi...'
                          : 'Gửi đánh giá',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFF4B5C),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
