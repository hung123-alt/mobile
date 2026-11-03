import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/episode_model.dart';
import 'package:cinema_app/widgets/episode_grid.dart';

Episode _createEpisode({
  required int id,
  required int episodeNumber,
  String serverName = 'Vietsub',
  String? title,
}) {
  return Episode(
    id: id,
    name: title ?? 'Tập $episodeNumber',
    description: 'Mô tả tập $episodeNumber',
    movieId: 1,
    episodeNumber: episodeNumber,
    title: title,
    embedUrl: 'https://player.example.com/ep$episodeNumber.m3u8',
    serverName: serverName,
    skipIntroSeconds: 0,
    durationSeconds: 2400,
    viewCount: 120,
  );
}

void main() {
  group('Kiểm thử lưới danh sách tập phim (EpisodeGrid)', () {
    testWidgets(
      'Hiển thị thông báo khi danh sách tập phim rỗng',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EpisodeGrid(
                episodes: const [],
                onEpisodeTap: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.text('Đang cập nhật tập phim'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Hiển thị danh sách tập phim và xử lý lựa chọn tập',
      (WidgetTester tester) async {
        Episode? tappedEpisode;
        final episodes = [
          _createEpisode(id: 1, episodeNumber: 1, title: '1'),
          _createEpisode(id: 2, episodeNumber: 2, title: '2'),
          _createEpisode(id: 3, episodeNumber: 3, title: '3'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EpisodeGrid(
                episodes: episodes,
                selectedEpisode: episodes.first,
                onEpisodeTap: (ep) {
                  tappedEpisode = ep;
                },
              ),
            ),
          ),
        );

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        await tester.tap(find.text('2'));
        await tester.pump();

        expect(tappedEpisode, isNotNull);
        expect(tappedEpisode!.id, 2);
        expect(tappedEpisode!.episodeNumber, 2);
      },
    );

    testWidgets(
      'Hiển thị và chuyển đổi giữa các server phát video',
      (WidgetTester tester) async {
        final episodes = [
          _createEpisode(
            id: 1,
            episodeNumber: 1,
            title: 'Tập 1 VS',
            serverName: 'Vietsub',
          ),
          _createEpisode(
            id: 2,
            episodeNumber: 1,
            title: 'Tập 1 TM',
            serverName: 'Thuyết minh',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EpisodeGrid(
                episodes: episodes,
                onEpisodeTap: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Vietsub'), findsOneWidget);
        expect(find.text('Thuyết minh'), findsOneWidget);
        expect(find.text('Tập 1 VS'), findsOneWidget);

        await tester.tap(find.text('Thuyết minh'));
        await tester.pump();

        expect(find.text('Tập 1 TM'), findsOneWidget);
      },
    );
  });
}

