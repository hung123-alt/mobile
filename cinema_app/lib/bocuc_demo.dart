import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LayoutDemo(),
    );
  }
}

/// Ô bo góc (1, 2, 3, 4) - chiều cao chia theo flex
class Box extends StatelessWidget {
  final int flex;
  final String label;
  const Box({super.key, required this.flex, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label),
      ),
    );
  }
}

class LayoutDemo extends StatelessWidget {
  const LayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(16),
          ),
          // ROW (children: [Column(children: [1, 2, 3, 4]), 2])
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cột bên trái: Column gồm 4 ô
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: const [
                      Box(flex: 1, label: '1'),
                      SizedBox(height: 15),
                      Box(flex: 4, label: '2'),
                      SizedBox(height: 15),
                      Box(flex: 1, label: '3'),
                      SizedBox(height: 15),
                      Box(flex: 2, label: '4'),
                    ],
                  ),
                ),
              ),
              // Phần tử 2 bên phải (rộng gấp đôi cột trái)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('2'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}