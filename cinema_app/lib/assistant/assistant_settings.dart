import 'package:cloud_firestore/cloud_firestore.dart';

import 'assistant_persona.dart';

/// Cài đặt trợ lý của từng user, lưu trong Firestore `users/{uid}`:
/// `assistantEnabled` (bool) + `assistantPersona` ("lina" | "seven").
class AssistantSettings {
  AssistantSettings._();

  static const String fieldEnabled = 'assistantEnabled';
  static const String fieldPersona = 'assistantPersona';

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _docId(String uid) => uid;

  /// Đọc cài đặt, mặc định tắt nếu chưa có.
  static Future<({bool enabled, AssistantPersona persona})> load(String uid) async {
    try {
      final doc = await _db.collection('users').doc(_docId(uid)).get();
      final data = doc.data();
      if (data == null) return (enabled: false, persona: AssistantPersona.lina);
      final enabled = data[fieldEnabled] == true;
      final persona = AssistantPersona.fromId(data[fieldPersona]?.toString());
      return (enabled: enabled, persona: persona);
    } catch (_) {
      return (enabled: false, persona: AssistantPersona.lina);
    }
  }

  /// Bật/tắt + chọn persona.
  static Future<void> save({
    required String uid,
    required bool enabled,
    required AssistantPersona persona,
  }) async {
    await _db.collection('users').doc(_docId(uid)).set(
      {
        fieldEnabled: enabled,
        fieldPersona: persona.id,
      },
      SetOptions(merge: true),
    );
  }
}
