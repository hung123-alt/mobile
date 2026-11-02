import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'assistant_brain.dart';
import 'assistant_persona.dart';

/// Cầu nối giọng nói: STT (vi-VN) + TTS (vi-VN) + chống echo + wake-word.
/// Luồng cứng chống tự nghe chính mình:
/// stop mic -> speak -> onComplete -> chờ guard 300ms -> mở mic lại.
class VoiceAssistantService extends ChangeNotifier {
  VoiceAssistantService({required this.brain}) {
    _tts.setCompletionHandler(_onTtsComplete);
    _tts.setCancelHandler(_onTtsComplete);
    _tts.setErrorHandler((_) => _onTtsComplete());
  }

  final AssistantBrain brain;

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _listening = false;
  bool _speaking = false;
  bool _enabled = true;
  Timer? _silenceTimer;
  Timer? _guardTimer;

  bool get listening => _listening;
  bool get speaking => _speaking;
  bool get enabled => _enabled;

  void setEnabled(bool v) {
    _enabled = v;
    if (!v) {
      stopAll();
    }
    notifyListeners();
  }

  Future<bool> initTts(AssistantPersona persona) async {
    try {
      await _tts.setLanguage('vi-VN');
      await _tts.setPitch(persona.pitch);
      await _tts.setSpeechRate(persona.speechRate);
      await _tts.setVolume(1.0);
      // Ưu tiên giọng vi-VN nếu máy có.
      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          for (final v in voices) {
            final m = v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
            final locale = '${m['locale'] ?? m['Locale'] ?? ''}'.toLowerCase();
            if (locale.startsWith('vi')) {
              await _tts.setVoice(Map<String, String>.from(
                  {'name': '${m['name'] ?? ''}', 'locale': '${m['locale'] ?? 'vi-VN'}'}));
              break;
            }
          }
        }
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> initStt() async {
    try {
      _sttReady = await _stt.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            _onSttDone();
          }
        },
        onError: (_) => _onSttDone(),
      );
      return _sttReady;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening({Duration silenceTimeout = const Duration(seconds: 8)}) async {
    if (!_enabled || _speaking) return;
    if (!_sttReady) {
      final ok = await initStt();
      if (!ok) return;
    }
    try {
      await stopSpeaking();
      brain.setListening();
      _listening = true;
      notifyListeners();
      _silenceTimer?.cancel();
      _silenceTimer = Timer(silenceTimeout, stopListening);
      // ignore: deprecated_member_use
      await _stt.listen(
        onResult: (r) {
          final text = r.recognizedWords.trim();
          if (text.isEmpty) return;
          // Wake-word: chỉ cần chứa tên là đánh thức.
          if (r.finalResult) {
            _silenceTimer?.cancel();
            stopListening();
            _onHeard(text);
          } else if (brain.isWakeWord(text)) {
            _silenceTimer?.cancel();
            stopListening();
            _onHeard(text);
          }
        },
        // ignore: deprecated_member_use
        localeId: 'vi-VN',
        // ignore: deprecated_member_use
        listenFor: const Duration(seconds: 30),
        // ignore: deprecated_member_use
        pauseFor: const Duration(seconds: 4),
        // ignore: deprecated_member_use
        cancelOnError: true,
        // ignore: deprecated_member_use
        partialResults: true,
      );
    } catch (_) {
      _listening = false;
      brain.setIdle();
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    if (!_listening) return;
    try {
      await _stt.stop();
    } catch (_) {}
    _listening = false;
    if (!_speaking) brain.setIdle();
    notifyListeners();
  }

  void _onSttDone() {
    _listening = false;
    if (!_speaking) brain.setIdle();
    notifyListeners();
  }

  Future<void> _onHeard(String text) async {
    if (!_enabled) return;
    brain.setListening();
    notifyListeners();
    final reply = await brain.handle(text, onAck: (ack) {
      // Nói câu đệm ngay khi tool chạy lâu (luật Mark-LIV).
      speak(ack, priority: true);
    });
    if (reply.isNotEmpty) {
      await speak(reply);
    }
  }

  /// Đọc to. priority=true dùng cho câu đệm, không chờ guard.
  Future<void> speak(String text, {bool priority = false}) async {
    if (!_enabled || text.trim().isEmpty) return;
    _guardTimer?.cancel();
    await stopListening();
    _speaking = true;
    brain.setSpeaking();
    notifyListeners();
    try {
      await _tts.stop();
      await initTts(brain.persona);
      await _tts.speak(text);
    } catch (_) {
      _onTtsComplete();
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
    notifyListeners();
  }

  void _onTtsComplete() {
    _speaking = false;
    brain.setIdle();
    notifyListeners();
    // Guard chống echo: mic mở lại sau 300ms.
    _guardTimer?.cancel();
    _guardTimer = Timer(const Duration(milliseconds: 300), () {
      if (_enabled && !_listening && !_speaking) {
        notifyListeners();
      }
    });
  }

  /// Người dùng bấm vào orb: toggle nghe / dừng nói.
  Future<void> toggle() async {
    if (_speaking) {
      await stopSpeaking();
      return;
    }
    if (_listening) {
      await stopListening();
      return;
    }
    await startListening();
  }

  Future<void> stopAll() async {
    _silenceTimer?.cancel();
    _guardTimer?.cancel();
    await stopListening();
    await stopSpeaking();
    brain.setIdle();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _guardTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}
