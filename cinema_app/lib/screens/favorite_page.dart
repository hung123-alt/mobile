import 'package:flutter/material.dart';

import 'base_screen.dart';

class FavoritePage extends BaseScreen<List<Map<String, String>>> {
  const FavoritePage({super.key})
    : super(
        data: const [
          {'title': 'Doraemon', 'genre': 'Hoạt hình', 'year': '2024'},
          {'title': 'Tây Du Ký', 'genre': 'Phiêu lưu', 'year': '1986'},
          {'title': 'Avengers', 'genre': 'Hành động', 'year': '2019'},
        ],
      );

  @override
  Widget buildContent(BuildContext context, List<Map<String, String>> movies) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phim yêu thích',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final movie = movies[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.movie)),
                    title: Text(movie['title']!),
                    subtitle: Text('${movie['genre']} • ${movie['year']}'),
                    trailing: const Icon(Icons.favorite, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
