import 'package:flutter/material.dart';
class LienHePage extends StatelessWidget {
   const LienHePage ({super.key});
    @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Liên Hệ'), backgroundColor: Colors.pink[100]),
    body: const Center(child: Text('Bấm nút để xem thông tin SV')),
    floatingActionButton: FloatingActionButton( 
      backgroundColor: Colors.pink[400],
      child: const Icon(Icons.person, color: Colors.white),
      onPressed: () {
        showDialog(
          context: context,
          builder:(_) => const AlertDialog(
            title: Text('Thông tin sinh viên'),
            content: Text('Họ và tên: Nguyễn Văn Thành Hưng\nMSSV: 24100101'),
          ),
        );
      },
     ),
    );
  }
}