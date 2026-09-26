import 'package:flutter/material.dart';
import 'widgets/navigation_shell.dart';

void main() {
  runApp(const CinemaApp());
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinema App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const BottomNavigationPage(title: 'Phenikaa Cinema'),
      debugShowCheckedModeBanner: false,
    );
  }
}
