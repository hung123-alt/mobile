import 'package:flutter/material.dart';

import '../models/User.dart';
import '../models/movie_model.dart';

class CinemaHomePage extends StatefulWidget {
  const CinemaHomePage({super.key});

  @override
  State<CinemaHomePage> createState() => _CinemaHomePageState();
}

class _CinemaHomePageState extends State<CinemaHomePage> {
  int _watchlistCount = 0;
  final user = User()..setUser(1, 'nguyenlethu', 'lethu@gmail.com', '123456');

  final movie = Movies(
    id: 1,
    title: 'Lật Mặt 7',
    description: 'Một bộ phim gia đình cảm động.',
    thumbnail: 'lat_mat_7.jpg',
    categoryId: 1,
    countryId: 1,
    releaseYear: 2024,
    movieType: 'Tâm lý',
    status: 'Đang chiếu',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  void _addToWatchlist() {
    setState(() {
      _watchlistCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              movie.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('${movie.movieType} - ${movie.releaseYear} - ${movie.status}'),
            const SizedBox(height: 16),
            Text(movie.description ?? 'Chưa có mô tả.'),
            const SizedBox(height: 24),
            Text('Tài khoản: ${user.username}'),
            const SizedBox(height: 8),
            Text('Đã thêm vào danh sách xem: $_watchlistCount phim'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addToWatchlist,
        tooltip: 'Thêm vào danh sách xem',
        icon: const Icon(Icons.playlist_add),
        label: const Text('Danh sách xem'),
      ),
    );
  }
}
