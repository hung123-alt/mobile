import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_routes.dart';


class CinematicIntroPage extends StatefulWidget {
  const CinematicIntroPage({super.key});

  @override
  State<CinematicIntroPage> createState() => _CinematicIntroPageState();
}

class _CinematicIntroPageState extends State<CinematicIntroPage>
    with SingleTickerProviderStateMixin {
  final _page = PageController();
  int _index = 0;
  Timer? _auto;
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_index >= 3) return; // cảnh cuối đứng yên chờ bấm
      _page.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _enter({bool markSeen = true}) async {
    _auto?.cancel();
    try {
      if (markSeen) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('cinematic_intro_seen', true);
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _SceneOne(loop: _loop),
                _SceneTwo(loop: _loop),
                _SceneThree(loop: _loop),
                _SceneFour(onStart: _enter),
              ],
            ),
            // Nút bỏ qua góc phải trên
            Positioned(
              top: 8,
              right: 12,
              child: TextButton(
                onPressed: _enter,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.fast_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
            // Chấm trang + nút điều hướng dưới cùng
            Positioned(
              left: 24,
              right: 24,
              bottom: 26,
              child: Row(
                children: [
                  Row(
                    children: List.generate(4, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 7),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFF4B5C)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  if (_index < 3)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _page.nextPage(
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeInOutCubic,
                      ),
                      child: const Text(
                        'Tiếp tục',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _enter,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Vào rạp ngay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cảnh 1: màn nhung mở ra + spotlight quét, chữ phim hiện từng chữ.
class _SceneOne extends StatelessWidget {
  final AnimationController loop;
  const _SceneOne({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final sweep = math.sin(loop.value * math.pi * 2);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Nền rạp
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B0B12), Color(0xFF1A0E1E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // 2 luồng spotlight
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(sweep: sweep),
              ),
            ),
            // Chữ chính reveal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đêm nay, rạp là của bạn',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1100),
                    builder: (context, v, _) {
                      return Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, (1 - v) * 26),
                          child: const Text(
                            'PHIM HAY\n24H',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              height: 0.95,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 64,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B5C),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hàng trăm phim lẻ, phim bộ, hoạt hình — mở là xem, không quảng cáo dài dòng.',
                    style: TextStyle(
                      color: Color(0xFFB8B8C4),
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cảnh 2: băng poster trôi vô hạn.
class _SceneTwo extends StatelessWidget {
  final AnimationController loop;
  const _SceneTwo({required this.loop});

  static const _titles = [
    'Hành động',
    'Tình cảm',
    'Kinh dị',
    'Viễn tưởng',
    'Cổ trang',
    'Hoạt hình',
  ];
  static const _colors = [
    Color(0xFFE50914),
    Color(0xFFEC4899),
    Color(0xFF00796B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        // 2 hàng trôi ngược chiều nhau
        final dx1 = (loop.value * 220) % 220;
        final dx2 = 220 - dx1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kho phim của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vuốt là thấy phim mới mỗi ngày. Thể loại nào cũng có, tìm không dấu vẫn ra.',
                style: TextStyle(
                  color: Color(0xFFB8B8C4),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              _MarqueeRow(
                offset: dx1,
                titles: _titles.sublist(0, 3),
                colors: _colors.sublist(0, 3),
              ),
              const SizedBox(height: 12),
              _MarqueeRow(
                offset: dx2,
                titles: _titles.sublist(3),
                colors: _colors.sublist(3),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarqueeRow extends StatelessWidget {
  final double offset;
  final List<String> titles;
  final List<Color> colors;
  const _MarqueeRow({
    required this.offset,
    required this.titles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: OverflowBox(
        maxWidth: MediaQuery.of(context).size.width + 220,
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: Offset(-offset, 0),
          child: Row(
            children: [
              for (var i = 0; i < 2; i++)
                for (var j = 0; j < titles.length; j++)
                  Container(
                    width: 200,
                    height: 118,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors[j], colors[j].withValues(alpha: 0.55)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      titles[j],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cảnh 3: Lina / Seven thở, giới thiệu trợ lý giọng nói.
class _SceneThree extends StatelessWidget {
  final AnimationController loop;
  const _SceneThree({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final breathe = 1 + 0.07 * math.sin(loop.value * math.pi * 2);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: breathe,
                    child: _MiniOrb(
                      letter: 'L',
                      colors: const [
                        Color(0xFFFF6FA5),
                        Color(0xFF7C6CFF),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  Transform.scale(
                    scale: 2 - breathe,
                    child: _MiniOrb(
                      letter: 'S',
                      colors: const [
                        Color(0xFF22D3A5),
                        Color(0xFF38BDF8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Gọi Lina hay Seven\nđều nghe lời bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nói "mở phim hành động hay" hay "tập 3 phim này" — trợ lý tự tìm, tự mở, tự phát.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB8B8C4),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniOrb extends StatelessWidget {
  final String letter;
  final List<Color> colors;
  const _MiniOrb({required this.letter, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.45),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Cảnh 4: chốt + CTA.
class _SceneFour extends StatelessWidget {
  final Future<void> Function() onStart;
  const _SceneFour({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B5C).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Xong phần giới thiệu',
              style: TextStyle(
                color: Color(0xFFFF8A95),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tắt đèn.\nBấm phát.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 58,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Lịch sử xem, yêu thích và trợ lý giọng nói đã sẵn sàng trong trang chủ.',
            style: TextStyle(
              color: Color(0xFFB8B8C4),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text(
                'Bắt đầu xem phim',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final double sweep;
  _SpotlightPainter({required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (final side in [-1, 1]) {
      final dx = size.width / 2 + side * sweep * size.width * 0.28;
      final path = Path()
        ..moveTo(size.width / 2, -20)
        ..lineTo(dx - 70, size.height * 0.75)
        ..lineTo(dx + 70, size.height * 0.75)
        ..close();
      canvas.drawPath(path, paint);
    }
    // Sàn sân khấu
    final floor = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x33FF4B5C), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.78),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.78),
      size.width * 0.55,
      floor,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.sweep != sweep;
}
