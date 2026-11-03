import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/core/utils/video_source.dart';

void main() {
  group('VideoSource.normalize (8a)', () {
    test('rong -> rong', () {
      expect(VideoSource.normalize(''), '');
      expect(VideoSource.normalize('   '), '');
    });

    test('tu them https khi thieu scheme', () {
      expect(
        VideoSource.normalize('vsmov.example.com/x.mp4'),
        'https://vsmov.example.com/x.mp4',
      );
    });

    test('YouTube watch -> embed', () {
      expect(
        VideoSource.normalize('https://www.youtube.com/watch?v=abc123DEF45'),
        'https://www.youtube.com/embed/abc123DEF45',
      );
    });

    test('YouTube youtu.be -> embed', () {
      expect(
        VideoSource.normalize('https://youtu.be/abc123DEF45'),
        'https://www.youtube.com/embed/abc123DEF45',
      );
    });

    test('YouTube shorts -> embed', () {
      expect(
        VideoSource.normalize('https://www.youtube.com/shorts/abc123DEF45'),
        'https://www.youtube.com/embed/abc123DEF45',
      );
    });

    test('YouTube giu tham so start ?t=90', () {
      expect(
        VideoSource.normalize('https://www.youtube.com/watch?v=abc123DEF45&t=90'),
        'https://www.youtube.com/embed/abc123DEF45?start=90',
      );
    });

    test('giu nguyen mp4 / m3u8 / vsmov', () {
      expect(
        VideoSource.normalize('https://cdn.example.com/a.mp4'),
        'https://cdn.example.com/a.mp4',
      );
      expect(
        VideoSource.normalize('https://cdn.example.com/a.m3u8'),
        'https://cdn.example.com/a.m3u8',
      );
    });
  });

  group('VideoSource.getYoutubeId (8d: thanh cong / that bai)', () {
    test('thanh cong: tach du 11 ky tu', () {
      expect(
        VideoSource.getYoutubeId('https://www.youtube.com/watch?v=abc123DEF45'),
        'abc123DEF45',
      );
    });

    test('that bai: khong phai youtube -> rong', () {
      expect(VideoSource.getYoutubeId('https://vsmov.example.com/x'), '');
      expect(VideoSource.getYoutubeId(''), '');
      expect(VideoSource.getYoutubeId('not a url'), '');
    });
  });

  group('VideoSource.classify (8d)', () {
    test('youtube', () {
      expect(
        VideoSource.classify('https://www.youtube.com/watch?v=abc123DEF45'),
        VideoSourceType.youtube,
      );
    });

    test('hls', () {
      expect(
        VideoSource.classify('https://cdn.example.com/live.m3u8'),
        VideoSourceType.hls,
      );
    });

    test('directVideo mp4', () {
      expect(
        VideoSource.classify('https://cdn.example.com/a.mp4'),
        VideoSourceType.directVideo,
      );
    });

    test('iframeEmbed (vsmov)', () {
      expect(
        VideoSource.classify('https://vsmov.example.com/embed/123'),
        VideoSourceType.iframeEmbed,
      );
    });

    test('unsupported: rong', () {
      expect(VideoSource.classify(''), VideoSourceType.unsupported);
    });
  });

  group('VideoSource.isSupported (8a: chan link doc hai)', () {
    test('chan scheme nguy hiem', () {
      expect(VideoSource.isSupported('javascript:alert(1)'), isFalse);
      expect(VideoSource.isSupported('data:text/html,hi'), isFalse);
      expect(VideoSource.isSupported('file:///etc/passwd'), isFalse);
      expect(VideoSource.isSupported('blob:https://x/1'), isFalse);
    });

    test('rong -> false', () {
      expect(VideoSource.isSupported(''), isFalse);
    });

    test('https hop le -> true', () {
      expect(
        VideoSource.isSupported('https://vsmov.example.com/embed/1'),
        isTrue,
      );
      expect(
        VideoSource.isSupported('https://cdn.example.com/a.mp4'),
        isTrue,
      );
    });

    test('http chi cho host dev local', () {
      expect(VideoSource.isSupported('http://localhost:3000/a.mp4'), isTrue);
      expect(VideoSource.isSupported('http://10.0.2.2:3000/a.mp4'), isTrue);
      expect(VideoSource.isSupported('http://evil.com/a.mp4'), isFalse);
    });
  });

  group('VideoSource.detectLabel / suggestServerName', () {
    test('detectLabel dung tung loai', () {
      expect(
        VideoSource.detectLabel('https://www.youtube.com/watch?v=abc123DEF45'),
        'YouTube',
      );
      expect(
        VideoSource.detectLabel('https://cdn.example.com/a.m3u8'),
        contains('HLS'),
      );
      expect(
        VideoSource.detectLabel('https://cdn.example.com/a.mp4'),
        contains('trực tiếp'),
      );
      expect(VideoSource.detectLabel(''), 'Link chưa hợp lệ');
    });

    test('suggestServerName: vsmov -> VSMOV', () {
      expect(
        VideoSource.suggestServerName('https://vsmov.example.com/e/1'),
        'VSMOV',
      );
      expect(
        VideoSource.suggestServerName('https://www.youtube.com/watch?v=abc123DEF45'),
        'YouTube',
      );
    });
  });
}
