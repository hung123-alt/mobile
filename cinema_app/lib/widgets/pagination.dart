import 'package:flutter/material.dart';

/// Widget phân trang dùng chung.
///
/// Dùng với `PageResult` trong `models/page_result.dart`
/// để lấy `getTotalPages()`, `getHasNext()`, `getNextPage()`.
class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChanged;

  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              currentPage > 1 ? () => onChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          '$currentPage / $totalPages',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => onChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
