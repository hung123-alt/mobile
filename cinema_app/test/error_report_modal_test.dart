import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/episode_model.dart';
import 'package:cinema_app/widgets/error_report_modal.dart';

void main() {
  group('Kiểm thử hộp thoại báo lỗi phim (ErrorReportModal)', () {
    final sampleEpisodes = [
      Episode(
        id: 10,
        name: 'Tập 1',
        description: 'Mô tả tập 1',
        movieId: 1,
        episodeNumber: 1,
        title: 'Tập 1',
        embedUrl: 'https://player.example.com/ep1.m3u8',
        serverName: 'Vietsub',
        skipIntroSeconds: 0,
        durationSeconds: 2400,
        viewCount: 50,
      ),
    ];

    testWidgets(
      'Kiểm tra bắt buộc nhập mô tả chi tiết khi gửi báo lỗi',
      (WidgetTester tester) async {
        bool submitted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorReportModal(
                movieName: 'Phim Kiểm Thử Báo Lỗi',
                episodes: sampleEpisodes,
                onSubmit: (episodeId, errorType, description) async {
                  submitted = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Báo lỗi phim'), findsOneWidget);
        expect(find.text('Phim Kiểm Thử Báo Lỗi'), findsOneWidget);

        await tester.ensureVisible(find.text('Gửi báo lỗi'));
        await tester.tap(find.text('Gửi báo lỗi'));
        await tester.pump();

        expect(find.text('Vui lòng nhập mô tả lỗi'), findsOneWidget);
        expect(submitted, isFalse);
      },
    );

    testWidgets(
      'Gửi đúng loại lỗi và mô tả chi tiết từ hộp thoại báo lỗi',
      (WidgetTester tester) async {
        int? reportedEpisodeId = -999;
        String? reportedErrorType;
        String? reportedDescription;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ErrorReportModal(
                          movieName: 'Đào, Phở và Piano',
                          episodes: sampleEpisodes,
                          onSubmit: (episodeId, errorType, description) async {
                            reportedEpisodeId = episodeId;
                            reportedErrorType = errorType;
                            reportedDescription = description;
                          },
                        ),
                      );
                    },
                    child: const Text('Mở báo lỗi'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mở báo lỗi'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField),
          'Tập 1 bị mất âm thanh ở phút thứ 15',
        );

        await tester.ensureVisible(find.text('Gửi báo lỗi'));
        await tester.tap(find.text('Gửi báo lỗi'));
        await tester.pumpAndSettle();

        expect(reportedEpisodeId, isNull); // Toàn bộ phim (-1 -> null)
        expect(reportedErrorType, 'video_not_load');
        expect(
          reportedDescription,
          'Tập 1 bị mất âm thanh ở phút thứ 15',
        );
      },
    );
  });
}

