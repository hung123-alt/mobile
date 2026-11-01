import 'base_entity.dart';

/// Model tập phim - kế thừa `BaseEntity<int>`
///
/// Khớp với collection `episodes` trên Firestore và `episode.entity.ts` ở server.
class Episode extends BaseEntity<int> {
  final int movieId;
  final int episodeNumber;
  final String? title;
  final String embedUrl;
  final String serverName;
  final int skipIntroSeconds;
  final int durationSeconds;
  final int viewCount;

  Episode({
    required super.id,
    required super.name,
    required super.description,
    required this.movieId,
    required this.episodeNumber,
    required this.title,
    required this.embedUrl,
    required this.serverName,
    required this.skipIntroSeconds,
    required this.durationSeconds,
    required this.viewCount,
  });

  /// Nhãn đầy đủ của tập: "Tập 1" hoặc "Tập Full"
  String getEpisodeLabel() {
    if (title != null && title!.trim().isNotEmpty) {
      final t = title!.trim();
      if (t.toLowerCase().startsWith('tập')) return t;
      return 'Tập $t';
    }
    return 'Tập $episodeNumber';
  }

  /// Nhãn ngắn gọn hiển thị trong ô nút bấm: "1", "2", "Full"...
  String getShortLabel() {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    return '$episodeNumber';
  }

  /// Định dạng thời lượng: 2700 giây -> "45:00"
  String getDurationLabel() {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secStr';
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  /// Parse từ JSON (hỗ trợ cả camelCase và snake_case từ Firestore / MySQL)
  factory Episode.fromJson(Map<String, dynamic> json) {
    final epNum = _parseInt(json['episodeNumber'] ?? json['episode_number'], 1);
    final rawTitle = (json['title'] ?? json['name'])?.toString();

    return Episode(
      id: _parseInt(json['id'], 0),
      name: rawTitle != null && rawTitle.isNotEmpty ? rawTitle : 'Tập $epNum',
      description: json['description'] as String? ?? '',
      movieId: _parseInt(json['movieId'] ?? json['movie_id'], 0),
      episodeNumber: epNum,
      title: rawTitle,
      embedUrl: (json['embedUrl'] ?? json['embed_url'])?.toString() ?? '',
      serverName:
          (json['serverName'] ?? json['server_name'])?.toString() ?? 'Vietsub',
      skipIntroSeconds:
          _parseInt(json['skipIntroSeconds'] ?? json['skip_intro_seconds'], 0),
      durationSeconds:
          _parseInt(json['durationSeconds'] ?? json['duration_seconds'], 0),
      viewCount: _parseInt(json['viewCount'] ?? json['view_count'], 0),
    );
  }
}
