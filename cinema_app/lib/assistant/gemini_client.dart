import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Client gọi trực tiếp Gemini REST `generateContent`.
/// Key lấy theo thứ tự: key dán trong app (panel chat) -> `--dart-define=GEMINI_API_KEY=...`.
/// Hỗ trợ cả 2 định dạng key cũ `AIza...` và mới `AQ....`.
/// Ladder rút gọn từ Mark-LIV: flash-lite trước, flash sau,
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

  /// Key dán tay trong app (panel chat), ưu tiên hơn --dart-define.
  /// Hỗ trợ cả key cũ `AIza...` lẫn key mới `AQ....`.
  static String? _manualKey;
  static void setManualKey(String? key) {
    final k = key?.trim();
    _manualKey = (k == null || k.isEmpty) ? null : k;
  }

  static String? get manualKey => _manualKey;

  /// Nạp key đã lưu trên máy (SharedPreferences) vào bộ nhớ.
  static Future<void> loadSavedKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('gemini_api_key')?.trim() ?? '';
      if (saved.isNotEmpty) _manualKey = saved;
    } catch (_) {}
  }

  /// Lưu key dán tay xuống máy để lần sau khỏi nhập lại.
  static Future<void> saveKey(String key) async {
    final k = key.trim();
    _manualKey = k.isEmpty ? null : k;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (k.isEmpty) {
        await prefs.remove('gemini_api_key');
      } else {
        await prefs.setString('gemini_api_key', k);
      }
    } catch (_) {}
  }

  /// Lỗi chi tiết của lần gọi gần nhất, để Brain hiện lên panel cho bạn thấy.
  /// Ví dụ: missing_key | http_400 | http_403 | http_404 | http_429 | network | empty.
  String? lastError;

  List<String> _keys() {
    final list = <String>[];
    final manual = _manualKey?.trim() ?? '';
    if (manual.isNotEmpty) list.addAll(_splitKeys(manual));
    const raw = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    list.addAll(_splitKeys(raw));
    // Bỏ trùng, giữ thứ tự: key dán tay trước.
    final seen = <String>{};
    return list.where((k) => seen.add(k)).toList();
  }

  static List<String> _splitKeys(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool get hasKey => _manualKey?.isNotEmpty == true || _keys().isNotEmpty;

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
      lastError =
          'missing_key: bạn dán key Gemini (AIza... hoặc AQ....) vào ô key trong khung chat rồi bấm Lưu, hoặc chạy kèm --dart-define=GEMINI_API_KEY=...';
      debugPrint('[Gemini] thiếu GEMINI_API_KEY');
      return null;
    }

    final ladder = <String>[];
    if (tier == 'flash') {
      ladder.add('gemini-2.5-flash');
    } else if (tier == 'lite') {
      ladder.add('gemini-2.5-flash-lite');
    } else {
      // Thử lần lượt, model mới trước, model cũ sau để tương thích key cũ/mới.
      ladder.addAll([
        'gemini-2.5-flash-lite',
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash-latest',
      ]);
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
            if (candidates == null || candidates.isEmpty) {
              lastError =
                  'empty: Gemini trả 200 nhưng không có candidates (${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body})';
              return null;
            }
            final content =
                candidates.first['content'] as Map<String, dynamic>?;
            lastError = null;
            return content;
          }
          if (resp.statusCode == 429) {
            lastError = 'http_429: $model hết quota, đang cooldown + xoay key';
            _cool(model);
            debugPrint('[Gemini] $model 429 -> cooldown + xoay key');
            continue;
          }
          final snippet = resp.body.length > 300
              ? resp.body.substring(0, 300)
              : resp.body;
          lastError = 'http_${resp.statusCode}: $model -> $snippet';
          if (resp.statusCode == 400 || resp.statusCode == 404) {
            debugPrint(
                '[Gemini] $model ${resp.statusCode}: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}');
            break; // model chết, sang nấc tiếp theo
          }
          debugPrint('[Gemini] $model ${resp.statusCode}: ${resp.body}');
          break;
        } catch (e) {
          lastError = 'network: $model lỗi kết nối ($e)';
          debugPrint('[Gemini] $model lỗi: $e');
          break;
        }
      }
    }
    return null;
  }

  void dispose() => _client.close();
}
