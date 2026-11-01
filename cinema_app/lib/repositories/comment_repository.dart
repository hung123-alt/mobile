import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../services/api_service.dart';
import '../services/comment_service.dart';

class CommentRepository {
  CommentRepository(this._commentService);

  final CommentService _commentService;

  
  Future<Comment?> create({
    required int movieId,
    required String content,
    int? parentId,
  }) async {
    try {
      return await _commentService.create(
        movieId: movieId,
        content: content,
        parentId: parentId,
      );
    } on ApiException catch (e) {
      debugPrint('CommentRepository.create lỗi: $e');
      return null;
    }
  }

  /// Danh sách bình luận của 1 phim.
  Future<List<Comment>> getByMovie(int movieId) async {
    try {
      return await _commentService.getByMovie(movieId);
    } on ApiException catch (e) {
      debugPrint('CommentRepository.getByMovie($movieId) lỗi: $e');
      return <Comment>[];
    }
  }

  /// Xóa bình luận. Trả `true` nếu thành công.
  Future<bool> remove(int commentId) async {
    try {
      await _commentService.remove(commentId);
      return true;
    } on ApiException catch (e) {
      debugPrint('CommentRepository.remove($commentId) lỗi: $e');
      return false;
    }
  }
}
