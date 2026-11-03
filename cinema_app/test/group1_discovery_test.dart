import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cinema_app/models/country_model.dart';
import 'package:cinema_app/models/episode_model.dart';
import 'package:cinema_app/models/genre_model.dart';
import 'package:cinema_app/models/movie_detail_result.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/rating_model.dart';
import 'package:cinema_app/providers/theme_provider.dart';
import 'package:cinema_app/widgets/movie_grid.dart';

Movie _createMovie({
  required int id,
  required String name,
  String slug = 'phim-test',
  String description = 'Mô tả phim kiểm thử',
  String type = 'phim_le',
  String status = 'completed',
  bool isVisible = true,
  bool isFeatured = false,
  double avgRating = 8.5,
  int ratingCount = 10,
  int totalEpisodes = 1,
  List<Genre> genres = const [],
  List<Country> countries = const [],
}) {
  return Movie(
    id: id,
    name: name,
    description: description,
    slug: '$slug-$id',
    posterUrl: 'https://example.com/poster_$id.jpg',
    bannerUrl: 'https://example.com/banner_$id.jpg',
    type: type,
    status: status,
    releaseYear: 2026,
    totalEpisodes: totalEpisodes,
    viewCount: 1500,
    avgRating: avgRating,
    ratingCount: ratingCount,
    isFeatured: isFeatured,
    isVisible: isVisible,
    scheduleDate: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    genres: genres,
    countries: countries,
  );
}

void main() {
  final genreAction = Genre(
    id: 1,
    name: 'Hành động',
    description: 'Phim hành động kịch tính',
    slug: 'hanh-dong',
    isVisible: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final genreRomance = Genre(
    id: 2,
    name: 'Tình cảm',
    description: 'Phim tình cảm lãng mạn',
    slug: 'tinh-cam',
    isVisible: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final genreHorror = Genre(
    id: 3,
    name: 'Kinh dị',
    description: 'Phim kinh dị',
    slug: 'kinh-di',
    isVisible: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleCatalog = <Movie>[
    _createMovie(
      id: 1,
      name: 'Vệ Binh Dải Ngân Hà',
      isVisible: true,
      genres: [genreAction],
    ),
    _createMovie(
      id: 2,
      name: 'Mắt Biếc',
      isVisible: true,
      genres: [genreRomance],
    ),
    _createMovie(
      id: 3,
      name: 'Chiến Binh Báo Đen',
      isVisible: true,
      genres: [genreAction],
    ),
    _createMovie(
      id: 4,
      name: 'Phim Nội Bộ Chưa Công Khai',
      isVisible: false,
      genres: [genreHorror],
    ),
  ];

  group('Nhóm 1 – Khám phá phim (US01 - US07)', () {
    // =========================================================================
    // US01: Là khách, tôi muốn xem danh sách phim trên trang chủ để khám phá nội dung.
    // Tiêu chí: Hiển thị phim được phép công khai; xử lý trạng thái không có dữ liệu.
    // =========================================================================
    group('US01 - Xem danh sách phim trên trang chủ', () {
      test('Chỉ trả về các bộ phim được phép công khai (isVisible == true)', () {
        final publicMovies =
            sampleCatalog.where((m) => m.isVisible).toList();

        expect(publicMovies.length, 3);
        expect(publicMovies.every((m) => m.isVisible), isTrue);
        expect(
          publicMovies.any((m) => m.name == 'Phim Nội Bộ Chưa Công Khai'),
          isFalse,
        );
      });

      testWidgets('Xử lý và hiển thị thông báo khi danh sách phim rỗng',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MovieGrid(
                movies: [],
              ),
            ),
          ),
        );

        expect(find.text('Chưa có phim nào.'), findsOneWidget);
      });
    });

    // =========================================================================
    // US02: Là khách, tôi muốn tìm kiếm phim theo tên để tìm nội dung mong muốn.
    // Tiêu chí: Kết quả phù hợp từ khóa, không phân biệt chữ hoa và chữ thường.
    // =========================================================================
    group('US02 - Tìm kiếm phim theo tên', () {
      List<Movie> searchMovies(List<Movie> source, String query) {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return [];
        return source
            .where((m) => m.isVisible && m.name.toLowerCase().contains(q))
            .toList();
      }

      test('Tìm kiếm khớp từ khóa không phân biệt chữ hoa và chữ thường', () {
        final lowerResult = searchMovies(sampleCatalog, 'mắt biếc');
        final upperResult = searchMovies(sampleCatalog, 'MẮT BIẾC');
        final mixedResult = searchMovies(sampleCatalog, 'vệ BINH');

        expect(lowerResult.length, 1);
        expect(lowerResult.first.id, 2);
        expect(upperResult.length, 1);
        expect(upperResult.first.id, 2);
        expect(mixedResult.length, 1);
        expect(mixedResult.first.name, 'Vệ Binh Dải Ngân Hà');
      });

      test('Trả về danh sách rỗng khi từ khóa không khớp hoặc để trống', () {
        expect(searchMovies(sampleCatalog, 'Spiderman'), isEmpty);
        expect(searchMovies(sampleCatalog, '   '), isEmpty);
      });
    });

    // =========================================================================
    // US03: Là khách, tôi muốn lọc phim theo thể loại để tìm nội dung phù hợp.
    // Tiêu chí: Chỉ hiển thị phim thuộc thể loại được chọn.
    // =========================================================================
    group('US03 - Lọc phim theo thể loại', () {
      List<Movie> filterByGenreSlug(List<Movie> source, String genreSlug) {
        return source
            .where(
              (m) =>
                  m.isVisible &&
                  m.genres.any((g) => g.slug == genreSlug),
            )
            .toList();
      }

      test('Chỉ hiển thị các phim thuộc thể loại được chọn', () {
        final actionMovies = filterByGenreSlug(sampleCatalog, 'hanh-dong');
        expect(actionMovies.length, 2);
        expect(
          actionMovies.every(
            (m) => m.genres.any((g) => g.slug == 'hanh-dong'),
          ),
          isTrue,
        );
      });

      test('Trả về rỗng nếu thể loại chưa có bộ phim công khai nào', () {
        final horrorPublic = filterByGenreSlug(sampleCatalog, 'kinh-di');
        expect(horrorPublic, isEmpty);
      });
    });

    // =========================================================================
    // US04: Là khách, tôi muốn xem danh sách thể loại để lựa chọn nhóm phim quan tâm.
    // Tiêu chí: Hiển thị các thể loại và số lượng phim tương ứng.
    // =========================================================================
    group('US04 - Xem danh sách thể loại và số lượng phim tương ứng', () {
      test('Tính toán chính xác số lượng phim công khai của từng thể loại', () {
        final genres = [genreAction, genreRomance, genreHorror];
        final publicMovies = sampleCatalog.where((m) => m.isVisible).toList();

        final genreCounts = <String, int>{
          for (final g in genres)
            g.name: publicMovies
                .where((m) => m.genres.any((mg) => mg.id == g.id))
                .length,
        };

        expect(genreCounts['Hành động'], 2);
        expect(genreCounts['Tình cảm'], 1);
        expect(genreCounts['Kinh dị'], 0);
      });
    });

    // =========================================================================
    // US05: Là khách, tôi muốn xem thông tin chi tiết phim để quyết định lựa chọn phim.
    // Tiêu chí: Hiển thị tên, ảnh, mô tả, thông tin tập và đánh giá tương ứng.
    // =========================================================================
    group('US05 - Xem thông tin chi tiết phim', () {
      test('Đầy đủ tên, ảnh, mô tả, danh sách tập và điểm đánh giá', () {
        final movie = sampleCatalog.first;
        final episodes = [
          Episode(
            id: 101,
            name: 'Tập 1',
            description: 'Tập mở đầu',
            movieId: movie.id,
            episodeNumber: 1,
            title: 'Tập 1',
            embedUrl: 'https://player.example.com/ep1',
            serverName: 'Vietsub',
            skipIntroSeconds: 30,
            durationSeconds: 2700,
            viewCount: 500,
          ),
        ];
        final detail = MovieDetailResult(
          movie: movie,
          episodes: episodes,
          genres: movie.genres,
          relatedMovies: [sampleCatalog[2]],
        );
        final rating = Rating(
          userId: 1,
          movieId: movie.id,
          score: 8,
          content: 'Phim kỹ xảo đẹp',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        expect(detail.movie.getName(), 'Vệ Binh Dải Ngân Hà');
        expect(detail.movie.displayImageUrl, isNotNull);
        expect(detail.movie.getDescription(), 'Mô tả phim kiểm thử');
        expect(detail.episodes.length, 1);
        expect(detail.episodes.first.getEpisodeLabel(), 'Tập 1');
        expect(detail.episodes.first.getDurationLabel(), '45:00');
        expect(detail.movie.getRating(), 8.5);
        expect(rating.getScoreOutOfFive(), 4.0);
        expect(rating.getScoreLabel(), 'Rất tốt');
      });
    });

    // =========================================================================
    // US06: Là khách, tôi muốn nhận gợi ý phim ngẫu nhiên để khám phá nội dung mới.
    // Tiêu chí: Hiển thị một phim hợp lệ từ danh sách có sẵn.
    // =========================================================================
    group('US06 - Nhận gợi ý phim ngẫu nhiên', () {
      Movie? pickRandomPublicMovie(List<Movie> catalog, int seedIndex) {
        final valid = catalog.where((m) => m.isVisible).toList();
        if (valid.isEmpty) return null;
        return valid[seedIndex % valid.length];
      }

      test('Trả về một bộ phim hợp lệ nằm trong danh sách phim công khai', () {
        final picked = pickRandomPublicMovie(sampleCatalog, 5);
        expect(picked, isNotNull);
        expect(picked!.isVisible, isTrue);
        expect(
          sampleCatalog.where((m) => m.isVisible).contains(picked),
          isTrue,
        );
      });

      test('Trả về null khi kho phim không có phim công khai nào', () {
        final emptyPicked = pickRandomPublicMovie([], 0);
        expect(emptyPicked, isNull);
      });
    });

    // =========================================================================
    // US07: Là khách, tôi muốn chuyển đổi giao diện sáng và tối để sử dụng ứng dụng thuận tiện hơn.
    // Tiêu chí: Giao diện thay đổi đúng chế độ được chọn.
    // =========================================================================
    group('US07 - Chuyển đổi giao diện sáng và tối (Theme)', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test('ThemeProvider chuyển đổi chính xác giữa Light Mode và Dark Mode',
          () async {
        final themeProvider = ThemeProvider.instance;
        await themeProvider.setDarkMode(false);
        expect(themeProvider.isDarkMode, isFalse);
        expect(themeProvider.themeMode, ThemeMode.light);

        await themeProvider.toggleTheme();
        expect(themeProvider.isDarkMode, isTrue);
        expect(themeProvider.themeMode, ThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('app_is_dark_mode'), isTrue);

        await themeProvider.toggleTheme();
        expect(themeProvider.isDarkMode, isFalse);
        expect(themeProvider.themeMode, ThemeMode.light);
      });
    });
  });
}

