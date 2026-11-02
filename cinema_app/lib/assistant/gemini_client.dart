import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Client gọi trực tiếp Gemini REST `generateContent`.
/// Key nằm trong app qua `--dart-define=GEMINI_API_KEY=...` (theo lựa chọn của bạn).
/// Kiến trúc ladder rút gọn từ Mark-LIV: flash-lite trước, flash sau,
/// model 429 thì cooldown 5 phút + xoay key (nhiều key cách nhau bằng dấu phẩy).
class GeminiClient {
  GeminiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const Duration defaultTimeout = Duration(seconds: 25);
  static const Duration cooldownTime = Duration(minutes: 5);
  static const int maxToolLoops = 5;

  final Map<String, DateTime> _cooldownUntil = {};

  List<String> _keys() {
    const raw = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool get hasKey => _keys().isNotEmpty;

  bool _cooling(String model) {
    final until = _cooldownUntil[model];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _cooldownUntil.remove(model);
    return false;
  }

  void _cool(String model) {
    _cooldownUntil[model] = DateTime.now().add(cooldownTime);
  }

  /// Gọi 1 lượt generateContent, tự đi ladder lite -> flash.
  /// Trả về JSON `candidates[0].content` thô để Brain xử lý tool-call.
  Future<Map<String, dynamic>?> generate({
    required String systemInstruction,
    required List<Map<String, dynamic>> contents,
    List<Map<String, dynamic>>? tools,
    String tier = 'auto',
  }) async {
    final keys = _keys();
    if (keys.isEmpty) {
      debugPrint('[Gemini] thiếu GEMINI_API_KEY (--dart-define)');
      return null;
    }

    final ladder = <String>[];
    if (tier == 'flash') {
      ladder.add('gemini-2.5-flash');
    } else if (tier == 'lite') {
      ladder.add('gemini-2.5-flash-lite');
    } else {
      ladder.addAll(['gemini-2.5-flash-lite', 'gemini-2.5-flash']);
    }

    for (final model in ladder) {
      if (_cooling(model)) continue;
      for (final key in keys) {
        try {
          final body = <String, dynamic>{
            'system_instruction': {
              'parts': [
                {'text': systemInstruction}
              ]
            },
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            },
          };
          if (tools != null && tools.isNotEmpty) {
            body['tools'] = [
              {'function_declarations': tools}
            ];
          }
          final resp = await _client
              .post(
                Uri.parse('$_base/$model:generateContent?key=$key'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(defaultTimeout);

          if (resp.statusCode == 200) {
            final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
            final candidates = decoded['candidates'] as List?;
            if (candidates == null || candidates.isEmpty) return null;
            final content =
                candidates.first['content'] as Map<String, dynamic>?;
            return content;
          }
          if (resp.statusCode == 429) {
            _cool(model);
            debugPrint('[Gemini] $model 429 -> cooldown + xoay key');
            continue;
          }
          if (resp.statusCode == 400 || resp.statusCode == 404) {
            debugPrint(
                '[Gemini] $model ${resp.statusCode}: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}');
            break; // model chết, sang nấc tiếp theo
          }
          debugPrint('[Gemini] $model ${resp.statusCode}: ${resp.body}');
          break;
        } catch (e) {
          debugPrint('[Gemini] $model lỗi: $e');
          break;
        }
      }
    }
    return null;
  }

  void dispose() => _client.close();
}
