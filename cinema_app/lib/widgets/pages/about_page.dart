import 'package:flutter/material.dart';
import '../page_layout.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageLayout(
      title: 'About',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 8),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.red,
              child: Icon(Icons.school, color: Colors.white, size: 50),
            ),
            SizedBox(height: 12),
            Text(
              'Phenikaa University',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Lap trinh Mobile - Flutter',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            SizedBox(height: 24),
            _InfoCard(
              icon: Icons.group,
              label: 'Nhom',
              value: 'Nhom 1 - Cinema App',
            ),
            _InfoCard(
              icon: Icons.school,
              label: 'Mon hoc',
              value: 'Lap trinh Mobile',
            ),
            _InfoCard(
              icon: Icons.calendar_today,
              label: 'Hoc ky',
              value: '2024 - 2025',
            ),
            _InfoCard(
              icon: Icons.code,
              label: 'Cong nghe',
              value: 'Flutter (Dart)',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
