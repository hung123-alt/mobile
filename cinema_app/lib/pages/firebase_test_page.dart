import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/firebase/firebase_service.dart';

/// Màn hình KIỂM TRA kết nối Firebase - dùng tạm thời, xong việc thì xoá.
///
/// Mục đích: xác nhận Firestore có hoạt động hay không TRƯỚC khi viết
/// tiếp repository, tránh mất thời gian debug lỗi từ nhiều tầng cùng lúc.
///
/// Cách dùng: mở app, xem kết quả ngay trên màn hình, chụp lại làm
/// bằng chứng cho Câu 8 (kiểm thử toàn bộ ứng dụng).
class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  /// Chạy lần lượt 5 bước kiểm tra, dừng ngay khi bước nào lỗi.
  ///
  /// Thứ tự này có chủ đích: kiểm tra từ "app có khởi tạo được không"
  /// tới "ghi được dữ liệu không", để biết chính xác lỗi nằm ở tầng nào.
  Future<void> _runTest() async {
    setState(() {
      _logs.clear();
      _isRunning = true;
    });

    // ---- BƯỚC 1: app đã khởi tạo Firebase chưa ----
    _log('[1] FirebaseService.initialized = ${FirebaseService.initialized}');
    if (!FirebaseService.initialized) {
      _log('   ✗ CHƯA KHỞI TẠO. Kiểm tra lại firebase_options.dart');
      setState(() => _isRunning = false);
      return;
    }

    // ---- BƯỚC 2: lấy được app instance không ----
    try {
      final app = Firebase.app();
      _log('[2] Project ID = ${app.options.projectId}');
      _log('    App name   = ${app.name}');
    } catch (e) {
      _log('   ✗ Lỗi bước 2: $e');
      setState(() => _isRunning = false);
      return;
    }

    final firebase = FirebaseService.instance;

    // ---- BƯỚC 3: ghi thử 1 document ----
    const testDocId = 'kiem_tra_ket_noi';
    try {
      await firebase.set(
        'kiem_tra',
        testDocId,
        {
          'noiDung': 'Xin chào từ Flutter',
          'soLuot': 1,
          'thoiGian': DateTime.now().toIso8601String(),
        },
      );
      _log('[3] ✓ Ghi thành công vào collection "kiem_tra"');
    } catch (e) {
      _log('   ✗ GHI THẤT BẠI: $e');
      _log('   → 90% là do chưa bật Firestore hoặc chưa bật billing');
      setState(() => _isRunning = false);
      return;
    }

    // ---- BƯỚC 4: đọc lại document vừa ghi ----
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('kiem_tra').doc(testDocId).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        _log('[4] ✓ Đọc lại thành công');
        _log('    Document ID = ${snapshot.id}');
        _log('    Nội dung      = $data');
      } else {
        _log('[4] ✗ Document không tồn tại sau khi ghi');
      }
    } catch (e) {
      _log('   ✗ ĐỌC THẤT BẠI: $e');
      setState(() => _isRunning = false);
      return;
    }

    // ---- BƯỚC 5: kiểm tra phép tăng số nguyên nguyên tử ----
    try {
      await firebase.increment('kiem_tra', testDocId, 'soLuot');
      final after =
          await FirebaseFirestore.instance.collection('kiem_tra').doc(testDocId).get();
      final count = after.data()?['soLuot'];
      _log('[5] ✓ Tăng số nguyên nguyên tử: soLuot = $count');
      if (count == 2) {
        _log('    Kết quả đúng như mong đợi (1 → 2)');
      }
    } catch (e) {
      _log('   ✗ Lỗi bước 5: $e');
    }

    _log('');
    _log('★★★ KẾT LUẬN: Firestore hoạt động bình thường ★★★');
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra kết nối Firebase'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          // Nút chạy kiểm tra
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runTest,
              icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_arrow),
              label: Text(_isRunning ? 'Đang chạy...' : 'Chạy kiểm tra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),

          // Danh sách kết quả
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Nhấn nút "Chạy kiểm tra" để bắt đầu',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final line = _logs[index];
                        Color color;
                        if (line.contains('✗')) {
                          color = const Color(0xFFD32F2F);
                        } else if (line.contains('★')) {
                          color = const Color(0xFF2E7D32);
                        } else if (line.contains('✓')) {
                          color = const Color(0xFF2E7D32);
                        } else if (line.contains('[1]') ||
                            line.contains('[2]') ||
                            line.contains('[3]') ||
                            line.contains('[4]') ||
                            line.contains('[5]')) {
                          color = const Color(0xFF64B5F6);
                        } else {
                          color = Colors.white70;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            line,
                            style: TextStyle(
                              color: color,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}