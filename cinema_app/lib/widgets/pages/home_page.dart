import 'package:flutter/material.dart';
import '../page_layout.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Trang chu',
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Banner lớn đầu trang
          _Banner(),
          const SizedBox(height: 16),
          // Section: Moi cap nhat
          const _SectionHeader(text: 'Moi cap nhat'),
          _MovieGrid(items: _newMovies, crossAxisCount: 3),
          const SizedBox(height: 16),
          // Section: Phim hay
          const _SectionHeader(text: 'Phim hay'),
          _MovieGrid(items: _hotMovies, crossAxisCount: 3),
          const SizedBox(height: 16),
          // Section: Phim le
          const _SectionHeader(text: 'Phim le'),
          _MovieGrid(items: _singleMovies, crossAxisCount: 3),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  // Dữ liệu giả - bạn có thể thay bằng model thật sau
  static const List<_Movie> _newMovies = [
    _Movie('Avengers', '2024', 8.4),
    _Movie('Inception', '2010', 8.8),
    _Movie('Avatar 2', '2022', 7.9),
    _Movie('Dune 2', '2024', 8.6),
    _Movie('Oppenheimer', '2023', 8.5),
    _Movie('Joker 2', '2024', 8.0),
  ];
  static const List<_Movie> _hotMovies = [
    _Movie('Dark Knight', '2008', 9.0),
    _Movie('Parasite', '2019', 8.5),
    _Movie('Interstellar', '2014', 8.7),
    _Movie('Spider-Man', '2021', 8.2),
  ];
  static const List<_Movie> _singleMovies = [
    _Movie('Top Gun 2', '2022', 8.3),
    _Movie('The Batman', '2022', 7.8),
    _Movie('John Wick 4', '2023', 7.7),
  ];
}
// ===== Widget con =====
class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Colors.black87, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PHIMHAY24H',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Xem phim hay moi ngay',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
class _MovieGrid extends StatelessWidget {
  const _MovieGrid({required this.items, required this.crossAxisCount});
  final List<_Movie> items;
  final int crossAxisCount;
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.62,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final m = items[index];
        return _MovieTile(title: m.title, year: m.year, rating: m.rating);
      },
    );
  }
}
class _Movie {
  const _Movie(this.title, this.year, this.rating);
  final String title;
  final String year;
  final double rating;
}
class _MovieTile extends StatelessWidget {
  const _MovieTile({
    required this.title,
    required this.year,
    required this.rating,
  });
  final String title;
  final String year;
  final double rating;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.movie, size: 32, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            const Icon(Icons.star, size: 11, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              rating.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
            const Spacer(),
            Text(
              year,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
