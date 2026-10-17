import 'package:flutter/material.dart';

import 'base_screen.dart';

class ProfilePage extends BaseScreen<Map<String, String>> {
  const ProfilePage({super.key})
    : super(
        data: const {
          'name': 'Người dùng PhimHay24h',
          'email': 'user@example.com',
        },
      );

  @override
  Widget buildContent(BuildContext context, Map<String, String> user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tài khoản',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user['name']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            user['email']!,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Thông tin cá nhân'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Lịch sử xem'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Cài đặt'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ],
    );
  }
}
