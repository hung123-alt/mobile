import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import 'movie_card.dart';

/// Lưới phim 3 cột hiển thị danh sách phim "MỚI CẬP NHẬT" chuẩn thiết kế.
class MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const MovieGrid({
    super.key,
    required this.movies,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Chưa có phim nào.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.54,
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) {
          return MovieCard(movie: movies[index]);
        },
      ),
    );
  }
}
