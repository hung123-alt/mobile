import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Danh sách phim
  final List<Map<String, String>> movies = const [
    {
      'title': 'Tình yêu và định mệnh',
      'image':
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
      'genre': 'Tình cảm',
      'episode': '16 tập',
    },
    {
      'title': 'Có đâu thương hạng',
      'image':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500',
      'genre': 'Tâm lý',
      'episode': '12 tập',
    },
    {
      'title': 'Sự trở lại của sát thủ',
      'image':
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=500',
      'genre': 'Hành động',
      'episode': '20 tập',
    },
    {
      'title': 'Vua trò chơi',
      'image':
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=500',
      'genre': 'Phiêu lưu',
      'episode': '8 tập',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: () {},
                  ),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'PhimHay',
                          style: TextStyle(
                            color: Color(0xFF172554),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '24h',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.dark_mode_outlined, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
              ),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm phim...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                'ĐANG THỊNH HÀNH',
                Colors.red,
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return _trendingMovie(
                      movies[index],
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle(
                'MỚI CẬP NHẬT',
                const Color(0xFF3B82F6),
              ),

              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movies.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 22,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  return _movieCard(
                    movies[index],
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
  }

  // =========================================================
  // TITLE CỦA SECTION
  // =========================================================

  Widget _sectionTitle(
    String title,
    Color color,
  ) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // =========================================================
  // PHIM THỊNH HÀNH
  // =========================================================

  Widget _trendingMovie(
    Map<String, String> movie,
  ) {
    return Container(
      width: 125,
      margin: const EdgeInsets.only(
        right: 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          movie['image']!,
          fit: BoxFit.cover,

          // Nếu ảnh không tải được
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.movie,
                size: 40,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // MOVIE CARD
  // =========================================================

  Widget _movieCard(
    Map<String, String> movie,
  ) {
    return GestureDetector(
      onTap: () {
        // Sau này mở trang chi tiết phim
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Poster
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                movie['image']!,
                width: double.infinity,
                fit: BoxFit.cover,

                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.movie,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tên phim
          Text(
            movie['title']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          // Thể loại + số tập
          Text(
            '${movie['genre']} • ${movie['episode']}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}