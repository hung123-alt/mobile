import 'package:flutter/material.dart';

import 'assistant_brain.dart';
import 'assistant_manager.dart';
import 'gemini_client.dart';

/// Panel chat trượt lên khi bấm vào orb.
/// Hỗ trợ cả gõ chữ và bấm mic, hiển thị lịch sử hội thoại.
class AssistantPanel extends StatefulWidget {
  const AssistantPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AssistantPanel(),
    );
  }

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  final _input = TextEditingController();
  final _keyInput = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  bool _showKeyBox = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    await GeminiClient.loadSavedKey();
    if (mounted) {
      setState(() {
        _showKeyBox = GeminiClient.manualKey == null;
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _keyInput.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendText(String text) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    try {
      final mgr = AssistantManager.instance;
      final reply = await mgr.brain.handle(t);
      if (reply.isNotEmpty) {
        await mgr.voice.speak(reply);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  Future<void> _saveKey() async {
    final k = _keyInput.text.trim();
    if (k.isEmpty) return;
    await GeminiClient.saveKey(k);
    _keyInput.clear();
    if (mounted) {
      setState(() => _showKeyBox = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu key Gemini trên máy này.')),
      );
    }
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: AssistantManager.instance,
      builder: (context, _) {
        final mgr = AssistantManager.instance;
        final persona = mgr.brain.persona;
        final messages = mgr.brain.history;
        final listening = mgr.voice.listening;
        final speaking = mgr.voice.speaking;

        final statusText = speaking
            ? '${persona.displayName} đang nói...'
            : listening
                ? 'Đang nghe...'
                : mgr.brain.state == AssistantState.thinking
                    ? '${persona.displayName} đang nghĩ...'
                    : 'Chào bạn, tôi là ${persona.displayName}';

        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 4),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          persona.primaryColor,
                          persona.secondaryColor,
                        ]),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        persona.displayName.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Nhập key Gemini',
                      icon: Icon(
                        Icons.vpn_key_rounded,
                        color: GeminiClient.manualKey != null
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF9CA3AF),
                      ),
                      onPressed: () =>
                          setState(() => _showKeyBox = !_showKeyBox),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (_showKeyBox)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keyInput,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: GeminiClient.manualKey == null
                                ? 'Dán key Gemini (AIza... hoặc AQ....)'
                                : 'Đã lưu key • dán key mới để thay',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                          ),
                          onSubmitted: (_) => _saveKey(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveKey,
                        child: const Text('Lưu'),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Bấm mic và nói, ví dụ:\n"mở phim hành động hay"\n"phim nào đang hot"\n"tập 3 của ${persona.displayName == 'Lina' ? 'Dấu Vết Trọn Đời' : 'Oppenheimer'}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isUser = m.role == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width *
                                        0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFFFF4B5C)
                                    : (isDark
                                        ? const Color(0xFF2A2A2A)
                                        : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF111827)),
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  top: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: _sendText,
                        decoration: InputDecoration(
                          hintText: 'Nhắn cho ${persona.displayName}...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          persona.primaryColor,
                          persona.secondaryColor,
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          listening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _busy
                            ? null
                            : () => AssistantManager.instance.voice.toggle(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4B5C),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                        onPressed:
                            _busy ? null : () => _sendText(_input.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
