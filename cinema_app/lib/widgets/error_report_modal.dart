
import 'package:flutter/material.dart';

import '../models/episode_model.dart';

class ErrorReportModal extends StatefulWidget {
  final String movieName;
  final List<Episode> episodes;

  final Future<void> Function(
    int? episodeId,
    String errorType,
    String description,
  ) onSubmit;

  const ErrorReportModal({
    super.key,
    required this.movieName,
    required this.episodes,
    required this.onSubmit,
  });

  @override
  State<ErrorReportModal> createState() =>
      _ErrorReportModalState();
}

class _ErrorReportModalState
    extends State<ErrorReportModal> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController =
      TextEditingController();

  int _selectedEpisodeId = -1;

  String _selectedErrorType = 'video_not_load';

  bool _isSubmitting = false;

  static const Color primaryColor =
      Color(0xFFFF4B5C);

  static const Map<String, String> errorTypes = {
    'video_not_load': 'Video không tải được',
    'wrong_episode': 'Sai nội dung hoặc sai tập phim',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final episodeId = _selectedEpisodeId == -1
          ? null
          : _selectedEpisodeId;

      await widget.onSubmit(
        episodeId,
        _selectedErrorType,
        _descriptionController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi báo lỗi thất bại: $error'),
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

    final inputColor = isDark
        ? const Color(0xFF292929)
        : const Color(0xFFF3F4F6);

    // Chỉ hiển thị tập có ID hợp lệ.
    final validEpisodes = widget.episodes
        .where((episode) => episode.id > 0)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.9,
        ),
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ===== TIÊU ĐỀ =====
                  Row(
                    children: [
                      const Icon(
                        Icons.report_problem_rounded,
                        color: primaryColor,
                        size: 27,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Báo lỗi phim',
                          style: TextStyle(
                            fontSize: 21,
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

                  const SizedBox(height: 10),

                  Text(
                    widget.movieName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Vui lòng cung cấp thông tin để chúng tôi xử lý lỗi.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== CHỌN TẬP PHIM =====
                  const Text(
                    'Tập phim gặp lỗi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<int>(
                    initialValue: _selectedEpisodeId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: -1,
                        child: Text('Toàn bộ phim'),
                      ),
                      ...validEpisodes.map(
                        (episode) =>
                            DropdownMenuItem<int>(
                          value: episode.id,
                          child: Text(
                            episode.getEpisodeLabel(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedEpisodeId =
                                  value ?? -1;
                            });
                          },
                  ),

                  const SizedBox(height: 22),

                  // ===== LÝ DO BÁO LỖI =====
                  const Text(
                    'Lý do báo lỗi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedErrorType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: errorTypes.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedErrorType = value;
                            });
                          },
                  ),

                  const SizedBox(height: 22),

                  // ===== MÔ TẢ =====
                  const Text(
                    'Mô tả chi tiết',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 1000,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Ví dụ: Tập 3 không phát được video...',
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả lỗi';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ===== NÚT GỬI =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Đang gửi...'
                            : 'Gửi báo lỗi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
