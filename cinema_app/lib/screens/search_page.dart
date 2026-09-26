import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tìm kiếm', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 48,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)),
              child: const TextField(
                decoration: InputDecoration(hintText: 'Nhập tên phim...', prefixIcon: Icon(Icons.search), border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Từ khóa phổ biến', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Hành động', 'Tình cảm', 'Hài', 'Kinh dị', 'Viễn tưởng']
                  .map((title) => Chip(label: Text(title)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}