import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Hành động', 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'name': 'Tình cảm', 'icon': Icons.favorite, 'color': Colors.pink},
    {'name': 'Hài', 'icon': Icons.emoji_emotions, 'color': Colors.orange},
    {'name': 'Kinh dị', 'icon': Icons.nightlight_round, 'color': Colors.purple},
    {'name': 'Viễn tưởng', 'icon': Icons.rocket_launch, 'color': Colors.blue},
    {'name': 'Phiêu lưu', 'icon': Icons.explore, 'color': Colors.green},
    {'name': 'Hoạt hình', 'icon': Icons.animation, 'color': Colors.amber},
    {'name': 'Tài liệu', 'icon': Icons.menu_book, 'color': Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thể loại', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final color = category['color'] as Color;
                  return Container(
                    decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category['icon'] as IconData, color: color, size: 32),
                        const SizedBox(height: 8),
                        Text(category['name'] as String, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}