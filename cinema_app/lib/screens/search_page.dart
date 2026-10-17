import 'package:flutter/material.dart';

import 'base_screen.dart';

class SearchPage extends BaseScreen<List<Map<String, String>>> {
  const SearchPage({super.key})
    : super(
        data: const [
          {'title': 'Doraemon', 'genre': 'Hoạt hình', 'year': '2024'},
          {'title': 'Tây Du Ký', 'genre': 'Phiêu lưu', 'year': '1986'},
          {'title': 'Avengers', 'genre': 'Hành động', 'year': '2019'},
          {'title': 'Your Name', 'genre': 'Tình cảm', 'year': '2016'},
        ],
      );

  @override
  Widget buildContent(BuildContext context, List<Map<String, String>> movies) {
    String keyword = '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm kiếm phim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setState) {
              final filteredMovies = movies.where((movie) {
                final title = movie['title']!.toLowerCase();
                final genre = movie['genre']!.toLowerCase();
                final query = keyword.toLowerCase();

                return title.contains(query) || genre.contains(query);
              }).toList();

              return Expanded(
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          keyword = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập tên phim hoặc thể loại...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredMovies.isEmpty
                          ? const Center(child: Text('Không tìm thấy phim'))
                          : ListView.builder(
                              itemCount: filteredMovies.length,
                              itemBuilder: (context, index) {
                                final movie = filteredMovies[index];

                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.movie),
                                    ),
                                    title: Text(movie['title']!),
                                    subtitle: Text(
                                      '${movie['genre']} • ${movie['year']}',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
