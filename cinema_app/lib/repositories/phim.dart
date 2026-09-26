import 'package:flutter/material.dart';

class StudentCheckInApp extends StatefulWidget {
  const StudentCheckInApp({super.key});

  @override
  State<StudentCheckInApp> createState() => _StudentCheckInAppState();
}

class _StudentCheckInAppState extends State<StudentCheckInApp> {
  int _checkInCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh sinh viên'),
      ),
      body: Center(
        child: Text(
          'Bạn đã điểm danh $_checkInCount lần.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _checkInCount++),
        tooltip: 'Thêm điểm danh',
        child: const Icon(Icons.check),
      ),
    );
  }
}