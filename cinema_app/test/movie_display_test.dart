import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/widgets/movie_card.dart';
import 'package:cinema_app/widgets/movie_grid.dart';

Movie _createSampleMovie({
  required int id,
  required String name,
  double avgRating = 8.6,
  String type = 'phim_bo',
  int totalEpisodes = 16,
}) {
  return Movie(
    id: id,
    name: name,
    description: 'Mô tả phim $name',
    slug: 'phim-$id',
    posterUrl: null,
    bannerUrl: null,
    type: type,
    status: 'ongoing',
    releaseYear: 2026,
    totalEpisodes: totalEpisodes,
    viewCount: 2500,
    avgRating: avgRating,
    ratingCount: 30,
    isFeatured: true,
    isVisible: true,
    scheduleDate: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    genres: const [],
    countries: const [],
  );
}

void main() {
  group('Kiểm thử hiển thị thẻ phim và lưới phim (MovieCard & MovieGrid)', () {
    testWidgets(
      'Hiển thị thông tin thẻ phim và xử lý sự kiện nhấn chọn phim',
      (WidgetTester tester) async {
        bool isTapped = false;
        final movie = _createSampleMovie(
          id: 1,
          name: 'Mưa Đỏ',
          avgRating: 9.2,
          type: 'phim_le',
          totalEpisodes: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 160,
                height: 260,
                child: MovieCard(
                  movie: movie,
                  onTap: () {
                    isTapped = true;
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('Mưa Đỏ'), findsOneWidget);
        expect(find.text('9.2'), findsOneWidget);
        expect(find.text('Phim Lẻ · 1 tập'), findsOneWidget);

        await tester.tap(find.text('Mưa Đỏ'));
        await tester.pump();

        expect(isTapped, isTrue);
      },
    );

    testWidgets(
      'Hiển thị trạng thái rỗng và danh sách phim trên lưới MovieGrid',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MovieGrid(movies: []),
            ),
          ),
        );

        expect(find.text('Chưa có phim nào.'), findsOneWidget);

        final movies = [
          _createSampleMovie(id: 1, name: 'Đào, Phở và Piano'),
          _createSampleMovie(id: 2, name: 'Lật Mặt 7'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MovieGrid(movies: movies),
              ),
            ),
          ),
        );

        expect(find.text('Đào, Phở và Piano'), findsOneWidget);
        expect(find.text('Lật Mặt 7'), findsOneWidget);
      },
    );
  });
}

