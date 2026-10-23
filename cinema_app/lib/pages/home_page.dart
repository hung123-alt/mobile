import 'package:flutter/material.dart';

/// Trang chủ - phim nổi bật, phim mới, lọc theo thể loại.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: const Center(
        child: Text('Trang chủ - TODO'),
      ),
    );
  }
}
