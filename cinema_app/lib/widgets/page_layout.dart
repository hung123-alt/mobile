import 'package:flutter/material.dart';
/// Widget dùng chung Header + Body + Footer cho mọi màn hình.
/// Style logo giống web PhimHay24h: chữ "PhimHay" màu đen + "24h" màu đỏ.
class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.title,
    required this.body,
  });
  final String title;
  final Widget body;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        Divider(height: 1, color: Colors.black.withOpacity(0.08)),
        _ScreenTitle(title: title),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: body,
          ),
        ),
        Divider(height: 1, color: Colors.black.withOpacity(0.08)),
        const _Footer(),
      ],
    );
  }
}
/// Logo "PhimHay 24h" đặt giữa + nút tìm kiếm bên phải (như web mẫu).
class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Spacer trái để đẩy logo ra giữa (giống web mẫu)
          const Spacer(),
          // Logo "PhimHay 24h" - chữ "PhimHay" đen + "24h" đỏ
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'PhimHay',
                  style: TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: '24h',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Nút tìm kiếm bên phải (icon)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
/// Footer theo đề thầy: "Phenikaa University, Tên sinh viên".
class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Column(
        children: [
          Text(
            'Phenikaa University',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          SizedBox(height: 2),
          Text(
            'Nguyen Le Thu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
