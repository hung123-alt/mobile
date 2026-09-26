import 'package:flutter/material.dart';
import '../page_layout.dart';
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final categories = const [
      _Cat('Hanht dong', Icons.local_fire_department, Color(0xFFFF6B6B)),
      _Cat('Tinh cam', Icons.favorite, Color(0xFFFF8FA3)),
      _Cat('Hai huoc', Icons.emoji_emotions, Color(0xFFFFB347)),
      _Cat('Kinh di', Icons.nightlight, Color(0xFF6C5CE7)),
      _Cat('Vien tuong', Icons.rocket_launch, Color(0xFF00B894)),
      _Cat('Phieu luu', Icons.explore, Color(0xFF0984E3)),
      _Cat('Anime', Icons.animation, Color(0xFFE84393)),
      _Cat('Co trang', Icons.castle, Color(0xFFDFE6E9)),
      _Cat('Chien tranh', Icons.military_tech, Color(0xFF2D3436)),
      _Cat('Tai lieu', Icons.article, Color(0xFF636E72)),
    ];
    return PageLayout(
      title: 'The loai',
      body: GridView.builder(
        itemCount: categories.length,
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, i) {
          final c = categories[i];
          return _CategoryCard(cat: c);
        },
      ),
    );
  }
}
class _Cat {
  const _Cat(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.cat});
  final _Cat cat;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            cat.color,
            cat.color.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(cat.icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            cat.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
