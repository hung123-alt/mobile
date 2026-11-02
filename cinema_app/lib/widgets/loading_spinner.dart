import 'package:flutter/material.dart';

/// Hiệu ứng loading quay dùng chung.
class LoadingSpinner extends StatelessWidget {
  final double size;
  final String? message;

  const LoadingSpinner({super.key, this.size = 36, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFFFF4B5C),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
