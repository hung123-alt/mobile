import 'base_entity.dart';

/// Model tập phim - kế thừa BaseEntity<int>
///
/// Khớp với server/src/modules/episodes/episode.entity.ts
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
    required int id,
    required String name,
    required String description,
    required this.movieId,
    required this.episodeNumber,
    required this.title,
    required this.embedUrl,
    required this.serverName,
    required this.skipIntroSeconds,
    required this.durationSeconds,
    required this.viewCount,
  }) : super(id: id, name: name, description: description);

  /// Nhãn tập: "Tập 5"
  String getEpisodeLabel() {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    return 'Tập $episodeNumber';
  }

  /// Định dạng thời lượng: 2700 giây -> "45:00"
  String getDurationLabel() {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secStr';
  }

  /// Parse từ JSON
  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int? ?? 0,
      name: json['title'] as String? ?? 'Tập ${json['episodeNumber'] ?? 1}',
      description: json['description'] as String? ?? '',
      movieId: json['movieId'] as int? ?? 0,
      episodeNumber: json['episodeNumber'] as int? ?? 1,
      title: json['title'] as String?,
      embedUrl: json['embedUrl'] as String? ?? '',
      serverName: json['serverName'] as String? ?? 'Server 1',
      skipIntroSeconds: json['skipIntroSeconds'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }
}
