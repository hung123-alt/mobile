import 'api_service.dart';
import '../models/comment_model.dart';


class CommentService {
  CommentService(this._api);

  final ApiService _api;

  /// Viết bình luận mới (hoặc trả lời 1 bình luận khác nếu có [parentId]).
  ///
  ///   POST /comments  body: { movieId, parentId?, content }
  Future<Comment> create({
    required int movieId,
    required String content,
    int? parentId,
  }) {
    return _api.post<Comment>(
      '/comments',
      {
        'movieId': movieId,
        'content': content,
        'parentId': ?parentId,
      },
      (raw) => Comment.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Danh sách bình luận của 1 phim (public, không cần đăng nhập).
  ///
  ///   GET /comments/movie/:movieId
  Future<List<Comment>> getByMovie(int movieId) {
    return _api.getList<Comment>(
      '/comments/movie/$movieId',
      (raw) => Comment.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Xóa bình luận của chính mình.
  ///
  ///   DELETE /comments/:id
  Future<void> remove(int commentId) {
    return _api.delete('/comments/$commentId');
  }
}
