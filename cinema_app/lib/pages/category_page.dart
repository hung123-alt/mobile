import 'package:flutter/material.dart';

/// Trang thể loại phim.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thể loại')),
      body: const Center(
        child: Text('Thể loại - TODO'),
      ),
    );
  }
}
