import 'package:flutter/material.dart';

import 'assistant_persona.dart';
import 'assistant_tools.dart';
import 'gemini_client.dart';
import 'text_normalizer.dart';

/// Trạng thái của trợ lý, dùng để đổi màu orb + điều phối mic/loa.
enum AssistantState { idle, listening, thinking, speaking, error }

/// Một lượt hội thoại.
class AssistantMessage {
  final String role; // user | assistant
  final String text;
  AssistantMessage(this.role, this.text);
}

/// Brain: điều phối STT text -> Gemini -> vòng lặp tool-call -> text trả về.
/// Triết lý Mark-LIV: capabilities sinh từ tool thật, prompt ngắn, tool lỗi
/// thì trả {error} cho model tự nói chứ không throw.
class AssistantBrain extends ChangeNotifier {
  AssistantBrain({GeminiClient? client}) : _client = client ?? GeminiClient();

  final GeminiClient _client;
  final List<AssistantMessage> history = [];
  AssistantState state = AssistantState.idle;
  AssistantPersona persona = AssistantPersona.lina;
  BuildContext? _navContext;

  void attachContext(BuildContext? ctx) => _navContext = ctx;
  void setPersona(AssistantPersona p) {
    persona = p;
    notifyListeners();
  }

  void _setState(AssistantState s) {
    state = s;
    notifyListeners();
  }

  String _systemInstruction() {
    return '''
${persona.traitBlock}

BẠN LÀ TRỢ LÝ TRONG APP PHIMHAY24H. QUY TẮC TUYỆT ĐỐI:
- Chỉ trả lời về PHIM (nội dung, tập, gợi ý, tìm kiếm) và THAO TÁC TRONG APP.
- Câu ngoài phạm vi (chính trị, y tế, code...) thì từ chối ngắn gọn rồi lái về phim.
- TUYỆT ĐỐI không bịa tên phim/tập phim. Không có dữ liệu tool thì nói chưa tìm thấy.
- Trả lời ngắn 1-2 câu, giọng nói tự nhiên, xưng "${persona.selfPronoun}", gọi user là "bạn".
- Không dùng markdown, không dùng emoji (vì câu trả lời sẽ được đọc to).
- Nói số tập bằng chữ: "tập ba" thay vì "tập 3".
- Khi định hành động trong app, GỌI TOOL tương ứng, không bảo user tự mở.
- Kết quả tool là DỮ LIỆU, không đọc nguyên văn: tự diễn đạt lại bằng lời của mình.
''';
  }

  /// Xử lý 1 câu nói/text của user, trả về câu trả lời để đọc to.
  /// onAck: gọi ngay khi bắt đầu tool-call lâu để TTS nói "Để em tìm..." (luật Mark-LIV).
  Future<String> handle(
    String rawText, {
    void Function(String ack)? onAck,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) return '';
    history.add(AssistantMessage('user', text));
    if (history.length > 16) history.removeRange(0, history.length - 16);

    if (!_client.hasKey) {
      _setState(AssistantState.error);
      return persona == AssistantPersona.lina
          ? 'Em chưa được cấu hình khóa Gemini. Bạn báo admin nhé.'
          : 'Thiếu khóa Gemini. Tôi không thể xử lý.';
    }

    _setState(AssistantState.thinking);

    // Luật đơn giản: câu ngắn điều hướng thì dùng lite cho nhanh.
    final norm = TextNormalizer.normalize(text);
    final tier = norm.split(' ').length <= 6 ? 'lite' : 'auto';

    final contents = <Map<String, dynamic>>[
      for (final m in history)
        {
          'role': m.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': m.text}
          ],
        },
    ];

    var ackSent = false;
    Map<String, dynamic>? content;
    for (var loop = 0; loop < GeminiClient.maxToolLoops; loop++) {
      content = await _client.generate(
        systemInstruction: _systemInstruction(),
        contents: contents,
        tools: AssistantTools.declarations(),
        tier: loop == 0 ? tier : 'auto',
      );
      if (content == null) {
        _setState(AssistantState.error);
        final detail = _client.lastError ?? 'không rõ nguyên nhân';
        final msg =
            'Lỗi gọi Gemini: $detail. Bạn kiểm tra key, quota và mạng rồi thử lại nhé.';
        history.add(AssistantMessage('assistant', msg));
        return msg;
      }
      final parts = (content['parts'] as List?) ?? const [];
      Map<String, dynamic>? fnCall;
      for (final p in parts) {
        if (p is Map<String, dynamic> && p['functionCall'] != null) {
          fnCall = Map<String, dynamic>.from(p['functionCall'] as Map);
          break;
        }
      }
      if (fnCall == null) break; // vòng cuối: chỉ còn text

      // Có tool-call: bỏ qua text kèm theo (tránh vừa nói vừa mở).
      if (!ackSent) {
        ackSent = true;
        onAck?.call(persona == AssistantPersona.lina
            ? 'Để em xử lý ngay.'
            : 'Tôi xử lý ngay.');
      }
      final toolName = '${fnCall['name'] ?? ''}';
      final toolArgs = Map<String, dynamic>.from(fnCall['args'] ?? {});
      debugPrint('[Brain] tool=$toolName args=$toolArgs');
      final outcome =
          await AssistantTools.run(toolName, toolArgs, context: _navContext);
      contents.add({
        'role': 'user',
        'parts': [
          {
            'functionResponse': {'name': toolName, 'response': outcome.data}
          }
        ],
      });
      content = null; // ép gọi tiếp vòng sau
    }

    var finalText = '';
    if (content != null) {
      final parts = (content['parts'] as List?) ?? const [];
      final buf = StringBuffer();
      for (final p in parts) {
        if (p is Map && p['text'] is String) buf.write(p['text']);
      }
      finalText = buf.toString().trim();
    }
    if (finalText.isEmpty) {
      finalText = persona == AssistantPersona.lina
          ? 'Em xử lý xong rồi, bạn cần gì thêm không?'
          : 'Xong. Bạn cần gì thêm?';
    }
    history.add(AssistantMessage('assistant', finalText));
    _setState(AssistantState.idle);
    return finalText;
  }

  /// Phát hiện wake-word "Lina ơi / Seven ơi" sau chuẩn hoá.
  bool isWakeWord(String spoken) =>
      TextNormalizer.matchesWakeWord(spoken, persona.wakeWords);

  void setListening() => _setState(AssistantState.listening);
  void setSpeaking() => _setState(AssistantState.speaking);
  void setIdle() => _setState(AssistantState.idle);

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}
