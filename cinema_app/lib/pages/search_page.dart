import 'package:flutter/material.dart';

/// Trang tìm kiếm phim.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: const Center(
        child: Text('Tìm kiếm - TODO'),
      ),
    );
  }
}
