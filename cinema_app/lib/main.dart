import 'package:flutter/material.dart';
import 'TrangChu.dart';
import 'NoiDung.dart';
import 'LienHe.dart';

void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.pink[50],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      home: const MainPage(),
    );
  }
}
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  int _index = 0;
  final List<Widget> _pages = const [
    TrangChuPage(),
    NoiDungPage(),
    LienHePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: Colors.pink[100], selectedItemColor: Colors.pink[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Nội Dung'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Liên Hệ'),
        ],
      ),
    );
  }
}