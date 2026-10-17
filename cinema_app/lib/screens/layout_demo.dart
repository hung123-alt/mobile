import 'package:flutter/material.dart';

class MovieLayoutDemoApp extends StatelessWidget {
  const MovieLayoutDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MovieLayoutPage(),
    );
  }
}
class MovieLayoutPage extends StatelessWidget {
  const MovieLayoutPage({super.key});

  // Khung  bên trái
  Widget _buildDetailsPanel() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF40E0D0),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: const MovieInfoPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    double width = MediaQuery.of(context).size.width;
    bool isWide = width >= 760;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.red,
                width: 3,
              ),
            ),
            child: ClipRect(
              child: isWide

                  
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // thông tin phim bên trái
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SingleChildScrollView(
                              child: _buildDetailsPanel(),
                            ),
                          ),
                        ),

                        // Phần ảnh phim bên phải
                        Expanded(
                          flex: 6,
                          child: MoviePoster(),
                        ),
                      ],
                    )

                
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 240,
                            child: MoviePoster(),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: _buildDetailsPanel(),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}


class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.network(
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ62iWYPaBnnM52pt4XjbctqyMKMxXtN-LRWjTrrUik1fDBlwqRm-QxiCnj&s=10'
        '?auto=format&fit=crop&w=1600&q=85',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black87,
            alignment: Alignment.center,
            child: const Icon(
              Icons.movie,
              size: 80,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}


class MovieInfoPanel extends StatelessWidget {
  const MovieInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Người Nhện: Khởi Đầu Mới',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),

        const SizedBox(height: 5),

        // Tên phim gốc
        const Text(
          'Spider-Man: Brand New Day',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF607D8B),
          ),
        ),

        const SizedBox(height: 12),

        // Tiêu đề nội dung
        const Text(
          'NỘI DUNG',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),

        const SizedBox(height: 6),

        // Mô tả phim
        const Text(
          'Peter Parker phải học cách sống một cuộc đời mới '
          'sau những biến cố lớn. Khi các mối đe dọa bí ẩn '
          'xuất hiện, anh tiếp tục hành trình bảo vệ thành phố '
          'và đối mặt với những thử thách chưa từng có.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF546E7A),
          ),
        ),

        const SizedBox(height: 12),

        // Đánh giá sao - STATEFULWIDGET
        const MovieRating(),

        const SizedBox(height: 12),

        // Các thông số phim
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 2,
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                child: MovieInfoItem(
                  icon: Icons.calendar_month,
                  label: 'NĂM PHÁT HÀNH',
                  value: '2026',
                ),
              ),

              Expanded(
                child: MovieInfoItem(
                  icon: Icons.schedule,
                  label: 'THỜI LƯỢNG',
                  value: '145 phút',
                ),
              ),

              Expanded(
                child: MovieInfoItem(
                  icon: Icons.movie_filter_outlined,
                  label: 'THỂ LOẠI',
                  value: 'Hành động',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================
// 5. ĐÁNH GIÁ SAO - STATEFULWIDGET
// ======================================================

class MovieRating extends StatefulWidget {
  const MovieRating({super.key});

  @override
  State<MovieRating> createState() => _MovieRatingState();
}

class _MovieRatingState extends State<MovieRating> {
  // Số sao mà người dùng chọn.
  // Ban đầu là 0 vì người dùng chưa đánh giá.
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Năm ngôi sao có thể nhấn
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    // Nhấn sao thứ mấy thì lấy số sao đó.
                    rating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                  ),
                  child: Icon(
                    index < rating
                        ? Icons.star
                        : Icons.star_border,
                    size: 23,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(width: 6),

          // Hiển thị kết quả đánh giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating == 0
                      ? 'Chưa đánh giá'
                      : 'Bạn chọn $rating/5 sao',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),

                const Text(
                  '120 lượt đánh giá',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 6. THÔNG SỐ PHIM - STATELESSWIDGET
// ======================================================

class MovieInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const MovieInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 21,
          color: const Color(0xFF80CBC4),
        ),

        const SizedBox(height: 5),

        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF607D8B),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
      ],
    );
  }
} 