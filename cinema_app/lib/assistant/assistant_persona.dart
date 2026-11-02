import 'package:flutter/material.dart';

/// Định nghĩa song sinh Lina / Seven.
/// Một bộ não duy nhất, chỉ khác 4 khe: tên, cách xưng, giọng đọc, màu sắc.
enum AssistantPersona {
  lina,
  seven;

  String get id => name;

  String get displayName => this == AssistantPersona.lina ? 'Lina' : 'Seven';

  /// Cách xưng trong câu trả lời.
  String get selfPronoun => this == AssistantPersona.lina ? 'em' : 'tôi';

  /// Cách gọi người dùng.
  String get userAddress => this == AssistantPersona.lina ? 'bạn' : 'bạn';

  /// Giọng đọc cho flutter_tts.
  double get pitch => this == AssistantPersona.lina ? 1.2 : 0.8;
  double get speechRate => this == AssistantPersona.lina ? 0.95 : 1.0;

  /// Màu chủ đạo của orb.
  Color get primaryColor => this == AssistantPersona.lina
      ? const Color(0xFFFF6FA5)
      : const Color(0xFF22D3A5);

  Color get secondaryColor => this == AssistantPersona.lina
      ? const Color(0xFF7C6CFF)
      : const Color(0xFF38BDF8);

  /// Từ đánh thức sau khi chuẩn hoá không dấu.
  List<String> get wakeWords => this == AssistantPersona.lina
      ? const ['lina oi', 'lina', 'em lina']
      : const ['seven oi', 'seven', 'anh seven'];

  /// Đoạn khí chất chèn vào systemInstruction.
  String get traitBlock => this == AssistantPersona.lina
      ? 'Bạn là Lina, trợ lý phim thân thiện, ấm áp, xưng "em", gọi người dùng là "bạn". '
          'Gợi ý phim kèm một câu rủ xem cùng, ngắn gọn.'
      : 'Bạn là Seven, trợ lý phim điềm tĩnh, gọn gàng, xưng "tôi", gọi người dùng là "bạn". '
          'Trả lời trực diện, không vòng vo, ưu tiên hành động.';

  /// Lời từ chối khi câu hỏi ra ngoài phạm vi phim.
  String outOfScopeReply(String userText) {
    if (this == AssistantPersona.lina) {
      return 'Em chỉ hỗ trợ về phim và các tính năng của Phim Hay 24h thôi ạ. '
          'Bạn muốn tìm phim gì hôm nay?';
    }
    return 'Tôi chỉ xử lý phim và tính năng trong app. Bạn cần tìm phim nào?';
  }

  static AssistantPersona fromId(String? id) {
    if (id == 'seven') return AssistantPersona.seven;
    return AssistantPersona.lina;
  }
}
