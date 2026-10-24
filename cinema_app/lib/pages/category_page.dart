import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';
import 'search_page.dart';

/// Trang Thể loại phim (Component 3 trong ảnh mẫu).
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      'name': 'Hành động',
      'colors': [Color(0xFF8B0000), Color(0xFFE50914)],
      'img': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&q=80',
    },
    {
      'name': 'Tình cảm',
      'colors': [Color(0xFFC2185B), Color(0xFFF06292)],
      'img': 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=400&q=80',
    },
    {
      'name': 'Kinh dị',
      'colors': [Color(0xFF004D40), Color(0xFF00796B)],
      'img': 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=400&q=80',
    },
    {
      'name': 'Hài',
      'colors': [Color(0xFFE65100), Color(0xFFFFA726)],
      'img': 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=400&q=80',
    },
    {
      'name': 'Hoạt hình',
      'colors': [Color(0xFF1565C0), Color(0xFF42A5F5)],
      'img': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&q=80',
    },
    {
      'name': 'Viễn tưởng',
      'colors': [Color(0xFF4A148C), Color(0xFF7E57C2)],
      'img': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&q=80',
    },
    {
      'name': 'Tâm lý',
      'colors': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      'img': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=400&q=80',
    },
    {
      'name': 'Phiêu lưu',
      'colors': [Color(0xFF006064), Color(0xFF26C6DA)],
      'img': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=400&q=80',
    },
    {
      'name': 'Cổ trang',
      'colors': [Color(0xFF512DA8), Color(0xFF9575CD)],
      'img': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&q=80',
    },
    {
      'name': 'Gia đình',
      'colors': [Color(0xFF37474F), Color(0xFF78909C)],
      'img': 'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'PhimHay',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: '24h',
                          style: TextStyle(
                            color: Color(0xFFFF4B5C),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: ThemeProvider.instance,
                    builder: (context, _) => IconButton(
                      icon: Icon(
                        ThemeProvider.instance.isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 22,
                        color: isDark ? Colors.amber : const Color(0xFF4B5563),
                      ),
                      onPressed: () => ThemeProvider.instance.toggleTheme(),
                    ),
                  ),
                ],
              ),
            ),

            // Tiêu đề: "Thể loại"
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Thể loại',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // Lưới thể loại 2 cột
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final List<Color> colors = cat['colors'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchPage(initialQuery: cat['name']),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Ảnh nền mờ nhẹ
                            Opacity(
                              opacity: 0.28,
                              child: Image.network(
                                cat['img'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            // Chữ tên thể loại giữa thẻ
                            Center(
                              child: Text(
                                cat['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
