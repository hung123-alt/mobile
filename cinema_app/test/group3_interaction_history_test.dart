import 'package:cinema_app/core/utils/validators.dart';
import 'package:cinema_app/models/comment_model.dart';
import 'package:cinema_app/models/episode_model.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/rating_model.dart';
import 'package:cinema_app/models/user_model.dart';
import 'package:cinema_app/providers/watch_history_provider.dart';
import 'package:cinema_app/widgets/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Movie _buildMovie({
  required int id,
  required String name,
  required String slug,
}) {
  return Movie(
    id: id,
    name: name,
    description: 'Mô tả $name',
    slug: slug,
    posterUrl: 'https://example.com/$slug.jpg',
    bannerUrl: 'https://example.com/${slug}_banner.jpg',
    type: 'phim_bo',
    status: 'ongoing',
    releaseYear: 2025,
    totalEpisodes: 12,
    viewCount: 500,
    avgRating: 8.0,
    ratingCount: 5,
    isFeatured: false,
    isVisible: true,
    scheduleDate: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    genres: const [],
    countries: const [],
  );
}

Episode _buildEpisode({
  required int id,
  required int movieId,
  required int episodeNumber,
  String? title,
  required String embedUrl,
}) {
  return Episode(
    id: id,
    name: title ?? 'Tập $episodeNumber',
    description: 'Mô tả tập $episodeNumber',
    movieId: movieId,
    episodeNumber: episodeNumber,
    title: title,
    embedUrl: embedUrl,
    serverName: 'Vietsub',
    skipIntroSeconds: 0,
    durationSeconds: 2400,
    viewCount: 100,
  );
}

/// Mô phỏng nghiệp vụ Tương tác & Lịch sử xem (Nhóm 3: US16 - US23)
class InteractionAndHistoryService {
  final List<Rating> _ratings = [];
  final List<Comment> _comments = [];
  final List<WatchHistoryRecord> _history = [];

  /// US16: Đánh giá phim thang 1-5 sao (tương ứng 1-10 điểm trong hệ thống)
  ({Rating? rating, String? error}) submitRating({
    required int userId,
    required int movieId,
    required int starsOutOfFive,
    String? content,
  }) {
    if (starsOutOfFive < 1 || starsOutOfFive > 5) {
      return (rating: null, error: 'Số sao đánh giá phải từ 1 đến 5 sao');
    }

    final scoreOutOfTen = starsOutOfFive * 2;
    final validationErr = Validators.rating(scoreOutOfTen.toString());
    if (validationErr != null) {
      return (rating: null, error: validationErr);
    }

    _ratings.removeWhere(
      (r) => r.userId == userId && r.movieId == movieId,
    );

    final now = DateTime.now();
    final newRating = Rating(
      userId: userId,
      movieId: movieId,
      score: scoreOutOfTen,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    _ratings.add(newRating);
    return (rating: newRating, error: null);
  }

  /// US17: Gửi bình luận về phim (hợp lệ từ 1 đến 500 ký tự)
  ({Comment? comment, String? error}) postComment({
    required User author,
    required int movieId,
    required String content,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return (comment: null, error: 'Nội dung bình luận không được để trống');
    }
    if (trimmed.length > 500) {
      return (
        comment: null,
        error: 'Bình luận không được vượt quá 500 ký tự',
      );
    }

    final nextId = _comments.length + 1;
    final now = DateTime.now();
    final comment = Comment(
      id: nextId,
      docId: 'cmt_$nextId',
      userId: author.id,
      movieId: movieId,
      parentId: null,
      content: trimmed,
      isHidden: false,
      createdAt: now,
      updatedAt: now,
      authorName: author.getDisplayName(),
    );
    _comments.add(comment);
    return (comment: comment, error: null);
  }

  /// US18: Xóa bình luận (chỉ tác giả hoặc quản trị viên được phép xóa)
  ({bool deleted, String? error}) deleteComment({
    required User requester,
    required int commentId,
  }) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      return (deleted: false, error: 'Không tìm thấy bình luận');
    }

    final target = _comments[index];
    final isAuthor = target.userId == requester.id;
    final isAdmin = requester.getIsAdmin();

    if (!isAuthor && !isAdmin) {
      return (
        deleted: false,
        error: 'Bạn không có quyền xóa bình luận của người khác',
      );
    }

    _comments.removeAt(index);
    return (deleted: true, error: null);
  }

  /// US19: Lấy danh sách tập phim thuộc bộ phim đang xem (sắp xếp theo tập)
  List<Episode> getEpisodesForMovie(
    List<Episode> allEpisodes,
    int movieId,
  ) {
    final filtered = allEpisodes
        .where((ep) => ep.movieId == movieId)
        .toList();
    filtered.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    return filtered;
  }

  /// US20: Ghi nhận phim vào lịch sử xem của đúng tài khoản, không tạo bản ghi trùng
  WatchHistoryRecord recordWatchHistory({
    required int userId,
    required Movie movie,
    Episode? episode,
    DateTime? watchedAt,
  }) {
    final timestamp = watchedAt ?? DateTime.now();
    final docId = '${userId}_${movie.id}';
    final epNum = episode?.episodeNumber ?? 1;

    // Loại bỏ bản ghi cũ của cùng (userId, movieId) để tránh trùng lặp
    _history.removeWhere(
      (item) => item.userId == userId && item.movie.id == movie.id,
    );

    final record = WatchHistoryRecord(
      docId: docId,
      id: movie.id,
      userId: userId,
      movie: movie,
      episodeId: episode?.id ?? 0,
      episodeNumber: epNum,
      episodeLabel: episode?.getEpisodeLabel() ?? 'Tập $epNum',
      watchedAt: timestamp,
    );
    _history.add(record);
    return record;
  }

  /// US21: Xem lịch sử xem phim của đúng tài khoản, sắp xếp mới nhất trước
  List<WatchHistoryRecord> getHistoryForUser(int userId) {
    final userRecords = _history
        .where((item) => item.userId == userId)
        .toList();
    userRecords.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return userRecords;
  }

  /// US22: Xóa một mục trong lịch sử xem (yêu cầu xác nhận & đúng chủ sở hữu)
  ({bool removed, String? error}) removeHistoryItem({
    required int currentUserId,
    required String docId,
    required bool isConfirmed,
  }) {
    if (!isConfirmed) {
      return (removed: false, error: 'Hủy thao tác xóa do chưa xác nhận');
    }

    final index = _history.indexWhere((item) => item.docId == docId);
    if (index == -1) {
      return (removed: false, error: 'Không tìm thấy mục lịch sử');
    }

    if (_history[index].userId != currentUserId) {
      return (
        removed: false,
        error: 'Không được phép xóa lịch sử của tài khoản khác',
      );
    }

    _history.removeAt(index);
    return (removed: true, error: null);
  }

  /// US23: Lựa chọn tập phim và kiểm tra nguồn phát video
  ({bool canPlay, Episode? episode, String? errorMessage}) selectEpisodeToPlay(
    Episode episode,
  ) {
    final url = episode.embedUrl.trim();
    final uri = Uri.tryParse(url);
    final isValidHttp =
        uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (url.isEmpty || !isValidHttp) {
      return (
        canPlay: false,
        episode: episode,
        errorMessage:
            'Đường dẫn video không hợp lệ hoặc nguồn phát không khả dụng',
      );
    }

    return (canPlay: true, episode: episode, errorMessage: null);
  }
}

void main() {
  late InteractionAndHistoryService service;

  final authorUser = User(
    id: 1,
    username: 'author',
    email: 'author@cinema.vn',
    avatarUrl: null,
    fullName: 'Tác Giả Bình Luận',
    role: 'user',
    isBanned: false,
    lastLogin: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final otherUser = User(
    id: 2,
    username: 'other',
    email: 'other@cinema.vn',
    avatarUrl: null,
    fullName: 'Người Dùng Khác',
    role: 'user',
    isBanned: false,
    lastLogin: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final adminUser = User(
    id: 99,
    username: 'admin',
    email: 'admin@cinema.vn',
    avatarUrl: null,
    fullName: 'Quản Trị Viên',
    role: 'admin',
    isBanned: false,
    lastLogin: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final movie1 = _buildMovie(
    id: 10,
    name: 'Đào, Phở và Piano',
    slug: 'dao-pho-va-piano',
  );

  final movie2 = _buildMovie(
    id: 20,
    name: 'Mắt Biếc',
    slug: 'mat-biec',
  );

  setUp(() {
    service = InteractionAndHistoryService();
  });

  group('Nhóm 3 – Tương tác và lịch sử xem (US16 - US23)', () {
    // =========================================================================
    // US16: Là người dùng, tôi muốn đánh giá phim bằng thang điểm từ 1 đến 5 sao
    // Tiêu chí: Điểm từ 1 đến 5 sao (1-10 điểm) được ghi nhận cho đúng phim và tài khoản.
    // =========================================================================
    group('US16 - Đánh giá phim thang điểm 1 đến 5 sao', () {
      test('Ghi nhận đúng điểm từ 1-5 sao (quy đổi 2-10 điểm) cho đúng phim và tài khoản', () {
        final res = service.submitRating(
          userId: authorUser.id,
          movieId: movie1.id,
          starsOutOfFive: 5,
          content: 'Phim rất xúc động',
        );

        expect(res.error, isNull);
        expect(res.rating, isNotNull);
        expect(res.rating!.userId, authorUser.id);
        expect(res.rating!.movieId, movie1.id);
        expect(res.rating!.score, 10);
        expect(res.rating!.getScoreOutOfFive(), 5.0);
        expect(res.rating!.getScoreLabel(), 'Tuyệt vời');
      });

      test('Từ chối điểm đánh giá nằm ngoài phạm vi 1 đến 5 sao', () {
        final tooLow = service.submitRating(
          userId: authorUser.id,
          movieId: movie1.id,
          starsOutOfFive: 0,
        );
        final tooHigh = service.submitRating(
          userId: authorUser.id,
          movieId: movie1.id,
          starsOutOfFive: 6,
        );

        expect(tooLow.rating, isNull);
        expect(tooLow.error, isNotNull);
        expect(tooHigh.rating, isNull);
        expect(tooHigh.error, isNotNull);
      });

      testWidgets('Widget RatingStars hiển thị đủ 5 ngôi sao và phản hồi khi chọn', (tester) async {
        int? selectedScore;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RatingStars(
                score: 8,
                readOnly: false,
                onChanged: (val) => selectedScore = val,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
        await tester.tap(find.byType(GestureDetector).last);
        expect(selectedScore, isNotNull);
        expect(selectedScore, inInclusiveRange(9, 10));
      });
    });

    // =========================================================================
    // US17: Là người dùng, tôi muốn gửi bình luận về phim để chia sẻ ý kiến
    // Tiêu chí: Bình luận hợp lệ từ 1 đến 500 ký tự được ghi nhận cho đúng phim.
    // =========================================================================
    group('US17 - Gửi bình luận về phim (1 - 500 ký tự)', () {
      test('Chấp nhận bình luận hợp lệ từ 1 đến 500 ký tự cho đúng movieId', () {
        final res = service.postComment(
          author: authorUser,
          movieId: movie1.id,
          content: 'Bối cảnh lịch sử được tái hiện rất chân thực!',
        );

        expect(res.error, isNull);
        expect(res.comment, isNotNull);
        expect(res.comment!.movieId, movie1.id);
        expect(res.comment!.userId, authorUser.id);
        expect(res.comment!.authorName, 'Tác Giả Bình Luận');
      });

      test('Từ chối bình luận rỗng hoặc vượt quá 500 ký tự', () {
        final emptyRes = service.postComment(
          author: authorUser,
          movieId: movie1.id,
          content: '    ',
        );
        expect(emptyRes.comment, isNull);
        expect(emptyRes.error, 'Nội dung bình luận không được để trống');

        final over500Text = 'a' * 501;
        final tooLongRes = service.postComment(
          author: authorUser,
          movieId: movie1.id,
          content: over500Text,
        );
        expect(tooLongRes.comment, isNull);
        expect(tooLongRes.error, 'Bình luận không được vượt quá 500 ký tự');
      });
    });

    // =========================================================================
    // US18: Là người dùng, tôi muốn xóa bình luận của mình để quản lý nội dung đã đăng
    // Tiêu chí: Chỉ tác giả hoặc người có quyền phù hợp được xóa bình luận.
    // =========================================================================
    group('US18 - Xóa bình luận (phân quyền tác giả và quản trị viên)', () {
      test('Tác giả hoặc Admin xóa bình luận thành công; người dùng khác bị từ chối', () {
        final posted = service.postComment(
          author: authorUser,
          movieId: movie1.id,
          content: 'Bình luận của tác giả',
        );
        final commentId = posted.comment!.id;

        // Người dùng khác cố xóa -> bị từ chối
        final unauthorizedAttempt = service.deleteComment(
          requester: otherUser,
          commentId: commentId,
        );
        expect(unauthorizedAttempt.deleted, isFalse);
        expect(
          unauthorizedAttempt.error,
          'Bạn không có quyền xóa bình luận của người khác',
        );

        // Chính tác giả xóa -> thành công
        final authorDelete = service.deleteComment(
          requester: authorUser,
          commentId: commentId,
        );
        expect(authorDelete.deleted, isTrue);

        // Đăng bình luận thứ 2 để kiểm tra quyền Admin xóa
        final posted2 = service.postComment(
          author: authorUser,
          movieId: movie1.id,
          content: 'Bình luận kiểm tra quyền Admin',
        );
        final adminDelete = service.deleteComment(
          requester: adminUser,
          commentId: posted2.comment!.id,
        );
        expect(adminDelete.deleted, isTrue);
      });
    });

    // =========================================================================
    // US19: Là khách, tôi muốn xem danh sách tập phim để lựa chọn nội dung cần xem
    // Tiêu chí: Hiển thị đúng danh sách tập thuộc phim đang xem.
    // =========================================================================
    group('US19 - Xem danh sách tập phim thuộc bộ phim đang xem', () {
      test('Chỉ lọc các tập thuộc movieId đang xem và sắp xếp theo thứ tự tập tăng dần', () {
        final allEpisodes = [
          _buildEpisode(
            id: 2,
            movieId: 10,
            episodeNumber: 2,
            title: 'Tập 2',
            embedUrl: 'https://stream.cinema.vn/m1/ep2.m3u8',
          ),
          _buildEpisode(
            id: 99,
            movieId: 20,
            episodeNumber: 1,
            title: 'Tập 1 phim khác',
            embedUrl: 'https://stream.cinema.vn/m2/ep1.m3u8',
          ),
          _buildEpisode(
            id: 1,
            movieId: 10,
            episodeNumber: 1,
            title: 'Tập 1',
            embedUrl: 'https://stream.cinema.vn/m1/ep1.m3u8',
          ),
        ];

        final movie1Episodes = service.getEpisodesForMovie(allEpisodes, 10);

        expect(movie1Episodes.length, 2);
        expect(movie1Episodes.every((e) => e.movieId == 10), isTrue);
        expect(movie1Episodes[0].episodeNumber, 1);
        expect(movie1Episodes[1].episodeNumber, 2);
        expect(movie1Episodes[0].getEpisodeLabel(), 'Tập 1');
      });
    });

    // =========================================================================
    // US20: Là người dùng, tôi muốn đánh dấu phim đã xem để lưu lại hoạt động xem phim
    // Tiêu chí: Phim được ghi nhận vào lịch sử của đúng tài khoản, không tạo bản ghi trùng.
    // =========================================================================
    group('US20 - Ghi nhận lịch sử xem phim không trùng lặp', () {
      test('Cập nhật bản ghi hiện có khi xem lại cùng một bộ phim thay vì tạo trùng lặp', () {
        final ep1 = _buildEpisode(
          id: 1,
          movieId: 10,
          episodeNumber: 1,
          embedUrl: 'https://stream.cinema.vn/ep1.m3u8',
        );
        final ep2 = _buildEpisode(
          id: 2,
          movieId: 10,
          episodeNumber: 2,
          embedUrl: 'https://stream.cinema.vn/ep2.m3u8',
        );

        service.recordWatchHistory(
          userId: authorUser.id,
          movie: movie1,
          episode: ep1,
          watchedAt: DateTime(2026, 3, 1, 20, 0),
        );
        service.recordWatchHistory(
          userId: authorUser.id,
          movie: movie1,
          episode: ep2,
          watchedAt: DateTime(2026, 3, 1, 21, 0),
        );

        final history = service.getHistoryForUser(authorUser.id);
        expect(history.length, 1);
        expect(history.first.movie.id, movie1.id);
        expect(history.first.episodeNumber, 2);
        expect(history.first.episodeLabel, 'Tập 2');
      });
    });

    // =========================================================================
    // US21: Là người dùng, tôi muốn xem lịch sử xem phim để tìm lại nội dung trước đó
    // Tiêu chí: Hiển thị lịch sử của đúng tài khoản, sắp xếp mới nhất trước.
    // =========================================================================
    group('US21 - Xem lịch sử xem phim sắp xếp mới nhất trước', () {
      test('Chỉ trả về lịch sử của đúng tài khoản và sắp xếp theo thời gian giảm dần', () {
        service.recordWatchHistory(
          userId: authorUser.id,
          movie: movie1,
          watchedAt: DateTime(2026, 3, 1, 10, 0),
        );
        service.recordWatchHistory(
          userId: authorUser.id,
          movie: movie2,
          watchedAt: DateTime(2026, 3, 2, 15, 30),
        );
        service.recordWatchHistory(
          userId: otherUser.id,
          movie: movie1,
          watchedAt: DateTime(2026, 3, 3, 9, 0),
        );

        final userHistory = service.getHistoryForUser(authorUser.id);

        expect(userHistory.length, 2);
        expect(userHistory[0].movie.id, movie2.id); // Mới hơn đứng trước
        expect(userHistory[1].movie.id, movie1.id);
        expect(
          userHistory.every((item) => item.userId == authorUser.id),
          isTrue,
        );
      });
    });

    // =========================================================================
    // US22: Là người dùng, tôi muốn xóa một mục trong lịch sử xem
    // Tiêu chí: Yêu cầu xác nhận trước khi xóa; chỉ xóa mục thuộc tài khoản hiện tại.
    // =========================================================================
    group('US22 - Xóa một mục trong lịch sử xem', () {
      test('Chỉ xóa khi người dùng đã xác nhận và mục lịch sử thuộc tài khoản hiện tại', () {
        final rec = service.recordWatchHistory(
          userId: authorUser.id,
          movie: movie1,
        );

        // Chưa xác nhận -> không xóa
        final unconfirmed = service.removeHistoryItem(
          currentUserId: authorUser.id,
          docId: rec.docId!,
          isConfirmed: false,
        );
        expect(unconfirmed.removed, isFalse);
        expect(service.getHistoryForUser(authorUser.id).length, 1);

        // Tài khoản khác cố xóa -> bị chặn
        final wrongOwner = service.removeHistoryItem(
          currentUserId: otherUser.id,
          docId: rec.docId!,
          isConfirmed: true,
        );
        expect(wrongOwner.removed, isFalse);
        expect(service.getHistoryForUser(authorUser.id).length, 1);

        // Chủ tài khoản xác nhận xóa -> thành công
        final confirmed = service.removeHistoryItem(
          currentUserId: authorUser.id,
          docId: rec.docId!,
          isConfirmed: true,
        );
        expect(confirmed.removed, isTrue);
        expect(service.getHistoryForUser(authorUser.id), isEmpty);
      });
    });

    // =========================================================================
    // US23: Là người xem, tôi muốn lựa chọn tập phim và phát video
    // Tiêu chí: Phát đúng tập đã chọn; hiển thị thông báo khi đường dẫn video
    //           không hợp lệ hoặc nguồn phát không khả dụng.
    // =========================================================================
    group('US23 - Lựa chọn tập phim và phát video', () {
      test('Phát đúng tập đã chọn khi đường dẫn embedUrl hợp lệ', () {
        final validEpisode = _buildEpisode(
          id: 30,
          movieId: 10,
          episodeNumber: 3,
          title: 'Trận chiến cuối cùng',
          embedUrl: 'https://player.cinema.vn/embed/movie_1_ep3.m3u8',
        );

        final playState = service.selectEpisodeToPlay(validEpisode);

        expect(playState.canPlay, isTrue);
        expect(playState.episode?.id, 30);
        expect(playState.episode?.episodeNumber, 3);
        expect(playState.errorMessage, isNull);
      });

      test('Hiển thị thông báo lỗi khi đường dẫn video rỗng hoặc sai giao thức', () {
        final emptyUrlEpisode = _buildEpisode(
          id: 31,
          movieId: 10,
          episodeNumber: 1,
          embedUrl: '   ',
        );
        final brokenUrlEpisode = _buildEpisode(
          id: 32,
          movieId: 10,
          episodeNumber: 2,
          embedUrl: 'invalid_url_stream',
        );

        final resEmpty = service.selectEpisodeToPlay(emptyUrlEpisode);
        final resBroken = service.selectEpisodeToPlay(brokenUrlEpisode);

        expect(resEmpty.canPlay, isFalse);
        expect(
          resEmpty.errorMessage,
          'Đường dẫn video không hợp lệ hoặc nguồn phát không khả dụng',
        );
        expect(resBroken.canPlay, isFalse);
        expect(
          resBroken.errorMessage,
          'Đường dẫn video không hợp lệ hoặc nguồn phát không khả dụng',
        );
      });
    });
  });
}
