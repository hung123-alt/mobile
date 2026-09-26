import 'package:flutter/material.dart';
import '../page_layout.dart';
class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});
  @override
  Widget build(BuildContext context) {
    final favs = const [
      _Fav('Inception', '2010', 8.8),
      _Fav('Avengers: Endgame', '2019', 8.4),
      _Fav('Avatar 2', '2022', 7.9),
      _Fav('Oppenheimer', '2023', 8.5),
      _Fav('Dune: Part Two', '2024', 8.6),
    ];
    return PageLayout(
      title: 'Yeu thich',
      body: favs.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: favs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final f = favs[i];
                return _FavTile(
                  title: f.title,
                  year: f.year,
                  rating: f.rating,
                );
              },
            ),
    );
  }
}
class _Fav {
  const _Fav(this.title, this.year, this.rating);
  final String title;
  final String year;
  final double rating;
}
class _FavTile extends StatelessWidget {
  const _FavTile({
    required this.title,
    required this.year,
    required this.rating,
  });
  final String title;
  final String year;
  final double rating;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Poster giả
          Container(
            width: 56,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.movie, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      year,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Nút trái tim đỏ (yêu thích)
          const Icon(Icons.favorite, color: Colors.red),
        ],
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Chua co phim yeu thich',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
