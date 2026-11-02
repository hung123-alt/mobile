import 'package:flutter/material.dart';

import 'assistant_brain.dart';
import 'assistant_persona.dart';
import 'assistant_settings.dart';
import 'voice_assistant_service.dart';
import '../providers/auth_provider.dart';

/// Singleton giữ Brain + Voice sống suốt phiên app.
/// Gắn 1 lần trong NavigationShell, orb và panel dùng chung.
class AssistantManager extends ChangeNotifier {
  AssistantManager._() {
    brain = AssistantBrain();
    voice = VoiceAssistantService(brain: brain);
    brain.addListener(_forward);
    voice.addListener(_forward);
  }

  static final AssistantManager instance = AssistantManager._();

  late final AssistantBrain brain;
  late final VoiceAssistantService voice;

  bool _enabled = false;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get loaded => _loaded;

  void _forward() => notifyListeners();

  /// Tải cài đặt từ Firestore sau khi đăng nhập.
  Future<void> loadForCurrentUser() async {
    final user = AuthProvider.instance.currentUser;
    if (user == null) {
      _enabled = false;
      _loaded = true;
      voice.setEnabled(false);
      notifyListeners();
      return;
    }
    final s = await AssistantSettings.load(user.id.toString());
    _enabled = s.enabled;
    _loaded = true;
    brain.setPersona(s.persona);
    voice.setEnabled(s.enabled);
    await voice.initTts(s.persona);
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    final user = AuthProvider.instance.currentUser;
    _enabled = v;
    voice.setEnabled(v);
    if (!v) {
      brain.setIdle();
    }
    notifyListeners();
    if (user != null) {
      await AssistantSettings.save(
        uid: user.id.toString(),
        enabled: v,
        persona: brain.persona,
      );
    }
  }

  Future<void> setPersona(AssistantPersona p) async {
    brain.setPersona(p);
    await voice.initTts(p);
    notifyListeners();
    final user = AuthProvider.instance.currentUser;
    if (user != null) {
      await AssistantSettings.save(
        uid: user.id.toString(),
        enabled: _enabled,
        persona: p,
      );
    }
  }

  @override
  void dispose() {
    brain.removeListener(_forward);
    voice.removeListener(_forward);
    super.dispose();
  }
}
