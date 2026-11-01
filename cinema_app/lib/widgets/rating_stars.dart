
import 'package:flutter/material.dart';

/// Hiển thị điểm 0–10 thành 5 sao.
/// Hỗ trợ chọn từng nửa sao (1–10 điểm).
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.score,
    this.readOnly = true,
    this.onChanged,
    this.size = 26,
    this.spacing = 2,
  });

  final double score;
  final bool readOnly;
  final ValueChanged<int>? onChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final current = score.clamp(0.0, 10.0).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled =
            (current / 2 - index).clamp(0.0, 1.0).toDouble();

        final star = SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Icon(
                Icons.star_border_rounded,
                color: Colors.amber,
                size: size,
              ),
              if (filled > 0)
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: filled,
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: size,
                    ),
                  ),
                ),
            ],
          ),
        );

        return Padding(
          padding: EdgeInsets.only(
            right: index == 4 ? 0 : spacing,
          ),
          child: readOnly || onChanged == null
              ? star
              : Semantics(
                  button: true,
                  label:
                      'Chọn ${index * 2 + 1} hoặc ${index * 2 + 2} điểm',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final half =
                          details.localPosition.dx < size / 2;

                      onChanged!(
                        index * 2 + (half ? 1 : 2),
                      );
                    },
                    child: star,
                  ),
                ),
        );
      }),
    );
  }
}
