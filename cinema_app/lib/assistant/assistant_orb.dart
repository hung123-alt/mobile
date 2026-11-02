import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'assistant_brain.dart';
import 'assistant_manager.dart';

/// Quả cầu hologram Lina/Seven ở góc màn hình.
/// Vẽ bằng CustomPainter nên không cần asset Lottie/Rive.
/// 4 trạng thái: idle (thở nhẹ) / listening (sóng lan) / thinking (xoay) / speaking (nhịp theo TTS).
class AssistantOrb extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const AssistantOrb({super.key, required this.onTap, this.size = 76});

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AssistantManager.instance,
      builder: (context, _) {
        final mgr = AssistantManager.instance;
        if (!mgr.loaded || !mgr.enabled) return const SizedBox.shrink();
        final persona = mgr.brain.persona;
        final state = mgr.brain.state;
        final speaking = mgr.voice.speaking;
        final listening = mgr.voice.listening;

        final effective = speaking
            ? AssistantState.speaking
            : listening
                ? AssistantState.listening
                : state;

        return GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _OrbPainter(
                    progress: _ctrl.value,
                    primary: persona.primaryColor,
                    secondary: persona.secondaryColor,
                    state: effective,
                    label: persona.displayName.substring(0, 1),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  final Color primary;
  final Color secondary;
  final AssistantState state;
  final String label;

  _OrbPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.state,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Bóng ngoài theo trạng thái.
    final glowR = switch (state) {
      AssistantState.listening => r * (1.02 + 0.06 * math.sin(progress * math.pi * 4)),
      AssistantState.thinking => r * 1.04,
      AssistantState.speaking => r * (1.03 + 0.05 * math.sin(progress * math.pi * 6)),
      AssistantState.error => r * 1.02,
      _ => r * (1.0 + 0.02 * math.sin(progress * math.pi * 2)),
    };
    final glow = Paint()
      ..color = (state == AssistantState.error ? Colors.redAccent : primary)
          .withValues(alpha: state == AssistantState.idle ? 0.25 : 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(c, glowR, glow);

    // Nền cầu.
    final bg = Paint()
      ..shader = RadialGradient(
        colors: [secondary.withValues(alpha: 0.9), primary.withValues(alpha: 0.95)],
        stops: const [0.25, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.92));
    canvas.drawCircle(c, r * 0.92, bg);

    // 3 vòng sóng theo trạng thái.
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      double rr;
      double alpha;
      switch (state) {
        case AssistantState.listening:
          rr = r * (0.55 + phase * 0.5);
          alpha = (1 - phase) * 0.7;
        case AssistantState.thinking:
          rr = r * (0.6 + 0.08 * math.sin((progress * math.pi * 4) + i));
          alpha = 0.55;
        case AssistantState.speaking:
          rr = r * (0.6 + 0.12 * math.sin((progress * math.pi * 6) + i * 1.2));
          alpha = 0.6;
        default:
          rr = r * (0.62 + 0.03 * math.sin(progress * math.pi * 2 + i));
          alpha = 0.35;
      }
      canvas.drawCircle(
        c,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: alpha),
      );
    }

    // Vòng xoay khi thinking.
    if (state == AssistantState.thinking) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.78),
        progress * math.pi * 4,
        math.pi * 1.2,
        false,
        arc,
      );
    }

    // Chữ cái đầu tên persona ở giữa.
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.progress != progress ||
      old.state != state ||
      old.primary != primary;
}
