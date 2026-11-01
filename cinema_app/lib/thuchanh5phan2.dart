import 'package:easy_stars/easy_stars.dart';
import 'package:flutter/material.dart';

// >>> LINK ẢNH BÓ THUỐC NỔ <<<
const String imageUrl =
    'https://thumbs.dreamstime.com/b/tnt-dynamite-bomb-white-background-d-illustration-high-resolution-65794289.jpg';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BombPage(),
    );
  }
}

// Khung ô dùng chung (Stateless): viền + bo góc, chiều cao chia theo flex
class InfoBox extends StatelessWidget {
  final int flex;
  final Widget child;
  const InfoBox({super.key, required this.flex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F8),
          border: Border.all(color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

// Phần tử 1: Tiêu đề (Stateless)
class TitleBox extends StatelessWidget {
  const TitleBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoBox(
      flex: 1,
      child: Center(
        child: FittedBox(
          child: Text(
            'Thuốc nổ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// Phần tử 2: Mô tả (Stateless)
class DescriptionBox extends StatelessWidget {
  const DescriptionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoBox(
      flex: 4,
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            'Thuốc nổ là chất nổ do Alfred Nobel phát minh năm 1867. '
            'Nó thường được dùng trong khai thác mỏ và xây dựng để phá đá, '
            'và chỉ những người được đào tạo mới được phép sử dụng.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// Phần tử 3: Review (StatefulWidget) - dùng easy_stars để đánh giá sao
class ReviewBox extends StatefulWidget {
  const ReviewBox({super.key});

  @override
  State<ReviewBox> createState() => _ReviewBoxState();
}

class _ReviewBoxState extends State<ReviewBox> {
  double _rating = 5; // số sao hiện tại, thay đổi khi người dùng chạm

  @override
  Widget build(BuildContext context) {
    return InfoBox(
      flex: 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dùng gói easy_stars để đánh giá sao
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: EasyStarsRating(
                initialRating: _rating,
                filledColor: Colors.green,
                onRatingChanged: (value) {
                  // Bắt dữ liệu người dùng chọn và cập nhật giao diện
                  setState(() => _rating = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${_rating.toStringAsFixed(0)}/5 · 170 Reviews'),
        ],
      ),
    );
  }
}

// Một cột thông tin nhỏ: icon + nhãn + giá trị (Stateless)
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.green[600]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Phần tử 4: Thông tin thuốc nổ (Stateless)
class DetailBox extends StatelessWidget {
  const DetailBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoBox(
      flex: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InfoItem(icon: Icons.person, label: 'NGƯỜI SÁNG CHẾ:', value: 'A. Nobel'),
          InfoItem(icon: Icons.calendar_today, label: 'NĂM:', value: '1867'),
          InfoItem(icon: Icons.construction, label: 'DÙNG ĐỂ:', value: 'Khai thác mỏ'),
        ],
      ),
    );
  }
}

// Cột bên trái: Column gồm 4 phần tử (Stateless)
class LeftColumn extends StatelessWidget {
  const LeftColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          TitleBox(),
          SizedBox(height: 10),
          DescriptionBox(),
          SizedBox(height: 10),
          ReviewBox(), // StatefulWidget duy nhất
          SizedBox(height: 10),
          DetailBox(),
        ],
      ),
    );
  }
}

// Phần tử 2 của Row: Hình ảnh lấy từ link (Stateless)
class BombImage extends StatelessWidget {
  const BombImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stack) => const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      ),
    );
  }
}

// Trang chính: Row(children: [Column(4 phần tử), Image])
class BombPage extends StatelessWidget {
  const BombPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 1, child: LeftColumn()),
              Expanded(flex: 2, child: BombImage()),
            ],
          ),
        ),
      ),
    );
  }
}