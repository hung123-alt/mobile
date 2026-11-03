import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/comment_model.dart';
import 'package:cinema_app/models/episode_model.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/movie_detail_result.dart';
import 'package:cinema_app/models/rating_model.dart';
import 'package:cinema_app/models/watchlist_item_model.dart';

void main() {
  group('Comment (8a/8d)', () {
    test('thanh cong: parse camelCase day du', () {
      final c = Comment.fromJson({
        'id': 1,
        'userId': 5,
        'movieId': 10,
        'parentId': null,
        'content': 'Hay',
        'isHidden': false,
        'authorName': 'Hung',
        'likeCount': 3,
        'likedUserIds': [1, 2, 3],
      });
      expect(c.id, 1);
      expect(c.getIsReply(), isFalse);
      expect(c.likeCount, 3);
    });

    test('la reply khi parentId > 0', () {
      final c = Comment.fromJson({
        'id': 2,
        'userId': 5,
        'movieId': 10,
        'parentId': 1,
        'content': 'Dong y',
      });
      expect(c.getIsReply(), isTrue);
    });

    test('that bai an toan: json rong -> default, khong throw', () {
      final c = Comment.fromJson({});
      expect(c.id, 0);
      expect(c.content, '');
      expect(c.likedUserIds, isEmpty);
      expect(c.getIsReply(), isFalse);
    });

    test('likeCount tu dong nang len bang likedUserIds (8a)', () {
      final c = Comment.fromJson({
        'id': 1,
        'userId': 1,
        'movieId': 1,
        'likeCount': 1,
        'likedUserIds': [1, 2, 3, 4],
      });
      expect(c.likeCount, 4);
    });

    test('getTimeAgoLabel bien', () {
      expect(Comment.fromJson({'id': 1}).getTimeAgoLabel(), 'Vừa xong');
      final now = DateTime.now();
      final c2 = Comment.fromJson({'id': 1}).copyWith(
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(c2.getTimeAgoLabel(), contains('phút trước'));
      final c3 = Comment.fromJson({'id': 1}).copyWith(
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(c3.getTimeAgoLabel(), contains('giờ trước'));
      final c4 = Comment.fromJson({'id': 1}).copyWith(
        createdAt: now.subtract(const Duration(days: 400)),
      );
      expect(c4.getTimeAgoLabel(), contains('/'));
    });

    test('snake_case tu MySQL cu', () {
      final c = Comment.fromJson({
        'id': '7',
        'user_id': '5',
        'movie_id': '10',
        'parent_id': '2',
        'like_count': 2,
        'is_hidden': 1,
      });
      expect(c.id, 7);
      expect(c.userId, 5);
      expect(c.parentId, 2);
      expect(c.isHidden, isTrue);
    });
  });

  group('Episode (8a/8d)', () {
    test('thanh cong + label', () {
      final e = Episode.fromJson({
        'id': 1,
        'movieId': 10,
        'episode_number': 3,
        'title': '3',
        'embed_url': 'https://vsmov.example.com/e/1',
        'duration_seconds': 2700,
      });
      expect(e.episodeNumber, 3);
      expect(e.getEpisodeLabel(), 'Tập 3');
      expect(e.getShortLabel(), '3');
      expect(e.getDurationLabel(), '45:00');
    });

    test('title "Full" -> giu nguyen', () {
      final e = Episode.fromJson({
        'id': 1,
        'movieId': 10,
        'episodeNumber': 1,
        'title': 'Full',
      });
      expect(e.getEpisodeLabel(), 'Tập Full');
      expect(e.getShortLabel(), 'Full');
    });

    test('that bai an toan: thieu -> default', () {
      final e = Episode.fromJson({});
      expect(e.id, 0);
      expect(e.episodeNumber, 1);
      expect(e.serverName, 'Vietsub');
      expect(e.getDurationLabel(), '0:00');
    });
  });

  group('Rating (8d)', () {
    test('getScoreOutOfFive', () {
      final r = Rating.fromJson({'userId': 1, 'movieId': 1, 'score': 8});
      expect(r.getScoreOutOfFive(), 4.0);
    });

    test('getScoreLabel bien', () {
      String label(int s) => Rating.fromJson(
        {'userId': 1, 'movieId': 1, 'score': s},
      ).getScoreLabel();
      expect(label(10), 'Tuyệt vời');
      expect(label(9), 'Tuyệt vời');
      expect(label(8), 'Rất tốt');
      expect(label(7), 'Rất tốt');
      expect(label(6), 'Tạm được');
      expect(label(5), 'Tạm được');
      expect(label(4), 'Tệ');
      expect(label(3), 'Tệ');
      expect(label(2), 'Rất tệ');
      expect(label(0), 'Rất tệ');
    });

    test('thieu -> default 0', () {
      final r = Rating.fromJson({});
      expect(r.score, 0);
      expect(r.content, isNull);
    });
  });

  group('MovieDetailResult + WatchlistItem (8d)', () {
    test('detail parse day du', () {
      final d = MovieDetailResult.fromJson({
        'movie': {'id': 1, 'title': 'A'},
        'episodes': [
          {'id': 1, 'movieId': 1, 'episodeNumber': 1},
        ],
        'genres': [
          {'id': 1, 'name': 'Hai'},
        ],
        'relatedMovies': [
          {'id': 2, 'title': 'B'},
        ],
      });
      expect(d.movie.id, 1);
      expect(d.episodes.length, 1);
      expect(d.genres.length, 1);
      expect(d.relatedMovies.length, 1);
    });

    test('detail thieu -> rong, khong throw', () {
      final d = MovieDetailResult.fromJson({});
      expect(d.episodes, isEmpty);
      expect(d.genres, isEmpty);
      expect(d.relatedMovies, isEmpty);
    });

    test('watchlist item kem movie', () {
      final w = WatchlistItem.fromJson({
        'id': 1,
        'userId': 2,
        'movieId': 3,
        'movie': {'id': 3, 'title': 'C'},
      });
      expect(w.movie?.id, 3);
    });

    test('watchlist item khong movie -> null', () {
      final w = WatchlistItem.fromJson({'id': 1, 'userId': 2, 'movieId': 3});
      expect(w.movie, isNull);
    });

    test('movie copyWith enrich (Home fix rot phim)', () {
      final m = Movie.fromJson({'id': 1, 'title': 'A'});
      expect(m.genres, isEmpty);
      final enriched = m.copyWith(genres: []);
      expect(enriched.id, 1);
    });
  });
}
