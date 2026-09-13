import 'package:flutter/material.dart';
import 'models/User.dart';         // Thêm import User
import 'models/movie_model.dart';  // Import Movies không còn bị báo lỗi thừa nữa

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // Sửa lỗi cú pháp .fromSeed thành ColorScheme.fromSeed
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // 1. Khởi tạo biến user1 và movie1 ở ngay trong State
  final user1 = User();
  
  final movie1 = Movies(
    id: 1,
    title: 'Lật Mặt 7',
    description: 'Một bộ phim gia đình cảm động.',
    thumbnail: 'lat_mat_7.jpg',
    categoryId: 1,
    countryId: 1,
    releaseYear: 2024,
    movieType: 'Tâm lý',
    status: 'Đang chiếu',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    // 2. Thiết lập dữ liệu cho user1 khi màn hình vừa mở lên
    user1.setUser(1, 'nguyenlethu', 'lethu@gmail.com', '123456');
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // Sửa lỗi cú pháp .center thành MainAxisAlignment.center
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            
            // Text hiển thị biến đếm
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            
            const SizedBox(height: 40), // Tạo khoảng trống
            
            // 3. Text hiển thị thông tin User
            Text(
              'User: ${user1.username} - ${user1.email}',
              style: const TextStyle(fontSize: 18, color: Colors.blue),
            ),
            
            const SizedBox(height: 10),
            
            // 4. Text hiển thị thông tin Movie
            Text(
              'Phim: ${movie1.title} (${movie1.releaseYear})',
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}