import 'package:flutter/material.dart';
class NoiDungPage extends StatelessWidget {
  const NoiDungPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Nội Dung'), backgroundColor: Colors.pink[100]),
    body: Center(
      child: Text('Nội dung bài thi giữa kỳ gồm 03 câu',
      style: TextStyle(fontSize: 20, color: Colors.pink[800], fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
       ),
     ),
    );
  }
}