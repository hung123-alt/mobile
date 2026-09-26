import 'package:flutter/material.dart';
import '../page_layout.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = [
      _Movie('Inception', 2010, 8.8),
      _Movie('Avengers: Endgame', 2019, 8.4),
      _Movie('Avatar: The Way of Water', 2022, 7.9),
      _Movie('Oppenheimer', 2023, 8.5),
      _Movie('Dune: Part Two', 2024, 8.6),
      _Movie('Joker', 2019, 8.2),
      _Movie('Parasite', 2019, 8.5),
      _Movie('The Dark Knight', 2008, 9.0),
      _Movie('Interstellar', 2014, 8.7),
      _Movie('Spider-Man: No Way Home', 2021, 8.2),
      _Movie('Top Gun: Maverick', 2022, 8.3),
      _Movie('The Batman', 2022, 7.8),
    ];

    return PageLayout(
      title: 'Movies',
      body: GridView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final m = movies[index];
          return _MovieTile(title: m.title, year: m.year, rating: m.rating);
        },
      ),
    );
  }
}

class _Movie {
  const _Movie(this.title, this.year, this.rating);
  final String title;
  final int year;
  final double rating;
}

class _MovieTile extends StatelessWidget {
  const _MovieTile({
    required this.title,
    required this.year,
    required this.rating,
  });
  final String title;
  final int year;
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
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.movie, size: 36, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$year',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Row(
          children: [
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 2),
            Text(
              rating.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}
