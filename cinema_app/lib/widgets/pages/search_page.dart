import 'package:flutter/material.dart';
import '../page_layout.dart';
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Tim kiem',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar bo tròn (giống web mẫu)
          TextField(
            decoration: InputDecoration(
              hintText: 'Tim ten phim...',
              prefixIcon: const Icon(Icons.search, color: Colors.red),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          // Lich su tim kiem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Lich su tim kiem',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'Xoa tat ca',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HistoryChip(text: 'Avengers'),
              _HistoryChip(text: 'Inception'),
              _HistoryChip(text: 'One Piece'),
              _HistoryChip(text: 'Naruto'),
              _HistoryChip(text: 'Joker'),
            ],
          ),
          const SizedBox(height: 20),
          // Phim goi y
          const Text(
            'Phim goi y',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: _SuggestionList(),
          ),
        ],
      ),
    );
  }
}
class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: () {},
    );
  }
}
class _SuggestionList extends StatelessWidget {
  const _SuggestionList();
  @override
  Widget build(BuildContext context) {
    final suggestions = const [
      'Avengers: Endgame',
      'Inception',
      'Avatar: The Way of Water',
      'Oppenheimer',
      'Dune: Part Two',
      'Spider-Man',
    ];
    return ListView.separated(
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, color: Colors.grey, size: 18),
          title: Text(suggestions[i], style: const TextStyle(fontSize: 13)),
          trailing: const Icon(Icons.north_west, color: Colors.grey, size: 16),
        );
      },
    );
  }
}
