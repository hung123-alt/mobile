
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase/collection_names.dart';
import '../models/movie_model.dart';

class RatingStats {
  final double average;
  final int count;

  const RatingStats({
    required this.average,
    required this.count,
  });
}

class RatingService {
  RatingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  // movies/{slug}/ratings/{uid}
  CollectionReference<Map<String, dynamic>> _ratings(Movie movie) {
    if (movie.slug.trim().isEmpty ||
        movie.slug.contains('/')) {
      throw ArgumentError('Phim không có slug hợp lệ.');
    }

    return _firestore
        .collection(CollectionNames.movies)
        .doc(movie.slug)
        .collection(CollectionNames.ratings);
  }

  // Thêm hoặc cập nhật đánh giá
  Future<void> rate({
    required Movie movie,
    required int score,
    String? content,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError(
        'Bạn cần đăng nhập bằng Firebase Authentication để đánh giá.',
      );
    }

    if (score < 1 || score > 10) {
      throw ArgumentError('Điểm đánh giá phải từ 1 đến 10.');
    }

    final cleanContent = content?.trim() ?? '';

    if (cleanContent.length > 1000) {
      throw ArgumentError('Nhận xét tối đa 1000 ký tự.');
    }

    final doc = _ratings(movie).doc(user.uid);

    final oldRating = await doc.get();

    final data = <String, dynamic>{
      'uid': user.uid,
      'movieId': movie.id,
      'score': score,
      'content': cleanContent,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!oldRating.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await doc.set(
      data,
      SetOptions(merge: true),
    );
  }

  // Lấy điểm người dùng đã đánh giá
  Future<int?> getMyScore(Movie movie) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) return null;

    final doc = await _ratings(movie)
        .doc(user.uid)
        .get();

    final score = doc.data()?['score'];

    if (score is num && score >= 1 && score <= 10) {
      return score.toInt();
    }

    return null;
  }

  // Theo dõi điểm trung bình theo thời gian thực
  Stream<RatingStats> watchStats(Movie movie) {
    return _ratings(movie).snapshots().map((snapshot) {
      int count = 0;
      double total = 0;

      for (final doc in snapshot.docs) {
        final score = doc.data()['score'];

        if (score is num && score >= 1 && score <= 10) {
          count++;
          total += score.toDouble();
        }
      }

      return RatingStats(
        average: count == 0 ? 0 : total / count,
        count: count,
      );
    });
  }
}
