import 'package:flutter/material.dart';
import '../page_layout.dart';
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: 'Tai khoan',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần thông tin user
          Center(
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                SizedBox(height: 10),
                Text(
                  'Nguyen Le Thu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  '1ethu@gmail.com',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Danh sách menu
          const _MenuTile(icon: Icons.edit, label: 'Chinh sua thong tin'),
          _Divider(),
          const _MenuTile(icon: Icons.lock, label: 'Doi mat khau'),
          _Divider(),
          const _MenuTile(icon: Icons.notifications, label: 'Thong bao'),
          _Divider(),
          const _MenuTile(icon: Icons.history, label: 'Lich su xem'),
          _Divider(),
          const _MenuTile(icon: Icons.help, label: 'Tro giup'),
          _Divider(),
          _Divider(),
          const _MenuTile(icon: Icons.logout, label: 'Dang xuat', color: Colors.red),
        ],
      ),
    );
  }
}
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.shade200);
  }
}
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.color = Colors.black87,
  });
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: color),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
