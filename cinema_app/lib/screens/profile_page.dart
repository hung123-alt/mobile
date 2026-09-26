import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tài khoản', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Center(child: CircleAvatar(radius: 50, backgroundColor: Colors.red, child: Icon(Icons.person, size: 50, color: Colors.white))),
          const SizedBox(height: 12),
          const Center(child: Text('Nguyen Le Thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Center(child: Text('1ethu@gmail.com', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),
          _item(Icons.edit, 'Chỉnh sửa hồ sơ'),
          _item(Icons.lock, 'Đổi mật khẩu'),
          _item(Icons.notifications, 'Thông báo'),
          _item(Icons.history, 'Lịch sử xem'),
          _item(Icons.help, 'Trợ giúp'),
          _item(Icons.logout, 'Đăng xuất', isLogout: true),
          const SizedBox(height: 16),
          const Divider(),
          const Center(child: Text('Phenikaa University - Nguyen Le Thu', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.black87),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black, fontWeight: isLogout ? FontWeight.bold : FontWeight.normal)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}