import 'package:flutter/material.dart';
class TrangChuPage extends StatelessWidget {
  const TrangChuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Trang Chủ'), backgroundColor: Colors.pink[100]),
    body: Center(child: Text(
      'Chào mừng bạn đến với ứng dụng KTGK',
      style: TextStyle(fontSize: 20, color:Colors.pink[800], fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      ),
     ),
    );
  }
}