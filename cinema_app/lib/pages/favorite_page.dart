import 'package:flutter/material.dart';

/// Trang danh sách yêu thích.
class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu thích')),
      body: const Center(
        child: Text('Yêu thích - TODO'),
      ),
    );
  }
}
