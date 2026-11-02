import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../core/firebase/user_auth_map_service.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

/// Giao diện Tab "Quản lý tài khoản" dành cho Admin (theo wireframe).
///
/// Toàn bộ số liệu (Tổng, Admin, User) và danh sách tài khoản đều được lấy động
/// và đồng bộ trực tiếp với bảng `users` trên Firestore.
class AdminUsersTab extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminUsersTab({super.key, this.onDataChanged});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<_AdminUserEntry> _allUsers = [];

  // Bộ lọc nhanh khi bấm vào 3 thẻ thống kê: 'all' | 'admin' | 'user'
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snap = await _firestore.collection(CollectionNames.users).get();
      final list = <_AdminUserEntry>[];

      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          final user = User.fromJson(data);
          list.add(
            _AdminUserEntry(
              docId: doc.id,
              user: user,
              rawData: data,
            ),
          );
        } catch (_) {}
      }

      // Sắp xếp Admin lên đầu hoặc theo ID/ngày tạo mới nhất
      list.sort((a, b) {
        if (a.user.getIsAdmin() != b.user.getIsAdmin()) {
          return a.user.getIsAdmin() ? -1 : 1;
        }
        final dA = a.user.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dB = b.user.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cmp = dB.compareTo(dA);
        if (cmp != 0) return cmp;
        return b.user.id.compareTo(a.user.id);
      });

      if (!mounted) return;
      setState(() {
        _allUsers = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminUsersTab load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get _adminCount =>
      _allUsers.where((item) => item.user.getIsAdmin()).length;

  int get _normalUserCount =>
      _allUsers.where((item) => !item.user.getIsAdmin()).length;

  List<_AdminUserEntry> get _filteredUsers {
    final q = _searchController.text.trim().toLowerCase();
    return _allUsers.where((entry) {
      final u = entry.user;
      if (_roleFilter == 'admin' && !u.getIsAdmin()) return false;
      if (_roleFilter == 'user' && u.getIsAdmin()) return false;

      if (q.isNotEmpty) {
        final matchUsername = u.username.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        final matchFullName =
            (u.fullName ?? '').toLowerCase().contains(q);
        return matchUsername || matchEmail || matchFullName;
      }
      return true;
    }).toList();
  }

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return '--/--/----';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  bool _isCurrentLoggedInAdmin(User target) {
    final current = AuthProvider.instance.currentUser;
    if (current == null) return false;
    return current.id == target.id ||
        (current.email.isNotEmpty &&
            current.email.toLowerCase() == target.email.toLowerCase());
  }

  /// Bật / Tắt trạng thái Hoạt động / Vô hiệu hóa (isBanned)
  Future<void> _toggleUserActiveStatus(
    _AdminUserEntry entry,
    bool isActive,
  ) async {
    if (!isActive && _isCurrentLoggedInAdmin(entry.user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không thể tự vô hiệu hóa tài khoản Admin đang đăng nhập!',
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newBanned = !isActive;
    final nowIso = DateTime.now().toIso8601String();

    // Cập nhật UI ngay lập tức
    setState(() {
      final idx = _allUsers.indexWhere((e) => e.docId == entry.docId);
      if (idx != -1) {
        _allUsers[idx] = _AdminUserEntry(
          docId: entry.docId,
          user: entry.user.copyWith(isBanned: newBanned),
          rawData: {
            ...entry.rawData,
            'isBanned': newBanned,
            'is_banned': newBanned ? 1 : 0,
          },
        );
      }
    });

    try {
      await _firestore
          .collection(CollectionNames.users)
          .doc(entry.docId)
          .set({
        'isBanned': newBanned,
        'is_banned': newBanned ? 1 : 0,
        'updatedAt': nowIso,
        'updated_at': nowIso,
      }, SetOptions(merge: true));

      widget.onDataChanged?.call();
    } catch (e) {
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật trạng thái thất bại: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Hộp thoại "+ Thêm tài khoản" mới
  Future<void> _showAddUserDialog() async {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'user';
    String? dialogError;
    bool isSubmitting = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Thêm tài khoản mới',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tên đăng nhập (username) *',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu * (tối thiểu 6 ký tự)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Vai trò',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('User (Người dùng)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin (Quản trị viên)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final uname = usernameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final pass = passwordCtrl.text;

                          if (uname.length < 3) {
                            setDialogState(() {
                              dialogError =
                                  'Username phải có ít nhất 3 ký tự';
                            });
                            return;
                          }
                          if (!email.contains('@')) {
                            setDialogState(() {
                              dialogError = 'Email không hợp lệ';
                            });
                            return;
                          }
                          if (pass.length < 6) {
                            setDialogState(() {
                              dialogError =
                                  'Mật khẩu phải có ít nhất 6 ký tự';
                            });
                            return;
                          }

                          final duplicateUser = _allUsers.any(
                            (e) =>
                                e.user.username.toLowerCase() ==
                                uname.toLowerCase(),
                          );
                          if (duplicateUser) {
                            setDialogState(() {
                              dialogError = 'Username này đã tồn tại';
                            });
                            return;
                          }

                          final duplicateEmail = _allUsers.any(
                            (e) =>
                                e.user.email.toLowerCase() ==
                                email.toLowerCase(),
                          );
                          if (duplicateEmail) {
                            setDialogState(() {
                              dialogError = 'Email này đã được sử dụng';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            int maxId = 0;
                            for (final item in _allUsers) {
                              if (item.user.id > maxId) maxId = item.user.id;
                            }
                            final nextId = maxId + 1;
                            final nowIso = DateTime.now().toIso8601String();

                            // Bảo mật: mật khẩu do Firebase Auth quản lý
                            // (đã hash + salt). Tạo tài khoản Auth TRƯỚC,
                            // rồi mới ghi hồ sơ Firestore — KHÔNG lưu
                            // plaintext password vào collection `users`.
                            //
                            // Dùng instance Auth phụ để KHÔNG ghi đè session
                            // của admin đang đăng nhập.
                            await AdminAuthService.createUser(
                              email: email,
                              password: pass,
                              displayName: uname,
                            );

                            await _firestore
                                .collection(CollectionNames.users)
                                .doc(nextId.toString())
                                .set({
                              'id': nextId,
                              'username': uname,
                              'email': email,
                              'role': selectedRole,
                              'isBanned': false,
                              'is_banned': 0,
                              'avatarUrl': null,
                              'avatar_url': null,
                              'createdAt': nowIso,
                              'created_at': nowIso,
                              'updatedAt': nowIso,
                              'updated_at': nowIso,
                            });

                            if (ctx.mounted) {
                              Navigator.pop(ctx, true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = 'Lỗi tạo tài khoản: $e';
                            });
                          }
                        },
                  child: Text(isSubmitting ? 'Đang tạo...' : 'Tạo tài khoản'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã thêm tài khoản mới thành công!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadUsers();
      widget.onDataChanged?.call();
    }
  }

  /// Hộp thoại Chỉnh sửa / Đổi vai trò / Xóa tài khoản khi bấm vào 1 dòng
  Future<void> _showEditUserDialog(_AdminUserEntry entry) async {
    final isSelf = _isCurrentLoggedInAdmin(entry.user);
    final usernameCtrl = TextEditingController(text: entry.user.username);
    final emailCtrl = TextEditingController(text: entry.user.email);
    final passwordCtrl = TextEditingController();
    String selectedRole = entry.user.getIsAdmin() ? 'admin' : 'user';
    bool isSaving = false;

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa tài khoản',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isSelf)
                    IconButton(
                      tooltip: 'Xóa tài khoản',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE11D48),
                      ),
                      onPressed: isSaving
                          ? null
                          : () => Navigator.pop(ctx, 'delete'),
                    ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tên đăng nhập (username)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (để trống nếu giữ nguyên)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Vai trò',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('User (Người dùng)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin (Quản trị viên)'),
                        ),
                      ],
                      onChanged: isSelf
                          ? null
                          : (val) {
                              if (val != null) {
                                setDialogState(() => selectedRole = val);
                              }
                            },
                    ),
                    if (isSelf) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Lưu ý: Không thể tự hạ quyền hoặc tự xóa tài khoản Admin đang đăng nhập.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(ctx, 'cancel'),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final uname = usernameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final newPass = passwordCtrl.text;
                          if (uname.isEmpty || email.isEmpty) return;

                          setDialogState(() => isSaving = true);
                          try {
                            final nowIso = DateTime.now().toIso8601String();
                            final payload = <String, dynamic>{
                              'username': uname,
                              'email': email,
                              'role': selectedRole,
                              'updatedAt': nowIso,
                              'updated_at': nowIso,
                            };

                            // Bảo mật: KHÔNG ghi plaintext password vào
                            // Firestore. Client SDK không đổi được mật khẩu
                            // hộ user khác, nên app gửi email reset mật khẩu
                            // cho họ tự đặt mật khẩu mới qua deep link.
                            if (newPass.isNotEmpty) {
                              final targetEmail =
                                  entry.user.email.trim().isEmpty
                                      ? email
                                      : entry.user.email.trim();

                              await AdminAuthService.requestPasswordReset(
                                email: targetEmail,
                              );

                              if (ctx.mounted) {
                                final messenger = ScaffoldMessenger.of(ctx);
                                Navigator.pop(ctx, 'saved');
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã gửi email đặt lại mật khẩu đến $targetEmail. '
                                      'Mật khẩu KHÔNG được lưu trong Firestore.',
                                    ),
                                    backgroundColor: Colors.green[700],
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              return;
                            }

                            await _firestore
                                .collection(CollectionNames.users)
                                .doc(entry.docId)
                                .set(payload, SetOptions(merge: true));

                            if (ctx.mounted) {
                              Navigator.pop(ctx, 'saved');
                            }
                          } catch (_) {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: Text(isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == 'saved') {
      await _loadUsers();
      widget.onDataChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật thông tin tài khoản!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (updated == 'delete') {
      if (!mounted) return;
      final confirmDel = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận xóa tài khoản'),
          content: Text(
            'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản "${entry.user.username}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B4E),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa vĩnh viễn'),
            ),
          ],
        ),
      );

      if (confirmDel == true) {
        await _firestore
            .collection(CollectionNames.users)
            .doc(entry.docId)
            .delete();
        await _loadUsers();
        widget.onDataChanged?.call();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa tài khoản "${entry.user.username}"!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final users = _filteredUsers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề "Quản lý tài khoản" + Nút "+ Thêm tài khoản"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý tài khoản',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Thêm tài khoản',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Hàng 3 thẻ thống kê: Tổng | Admin | User (bấm để lọc nhanh)
          Row(
            children: [
              Expanded(
                child: _buildRoleSummaryCard(
                  filterKey: 'all',
                  icon: Icons.person_outline_rounded,
                  iconColor:
                      isDark ? Colors.white70 : const Color(0xFF4B5563),
                  label: 'Tổng',
                  count: _isLoading
                      ? '...'
                      : _formatNumber(_allUsers.length),
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRoleSummaryCard(
                  filterKey: 'admin',
                  icon: Icons.workspace_premium_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Admin',
                  count: _isLoading ? '...' : _formatNumber(_adminCount),
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRoleSummaryCard(
                  filterKey: 'user',
                  icon: Icons.group_outlined,
                  iconColor: const Color(0xFF9333EA),
                  label: 'User',
                  count: _isLoading ? '...' : _formatNumber(_normalUserCount),
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Thanh tìm kiếm tài khoản
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài khoản (username, email...)',
                hintStyle: TextStyle(fontSize: 13.5, color: textSecondary),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Bảng danh sách tài khoản
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border.all(color: borderColor.withValues(alpha: 0.7)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header bảng: Tài khoản | Vai trò | Ngày tham gia | Trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    color: isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFF1F3F7),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 42,
                          child: Text(
                            'Tài khoản',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: Text(
                            'Vai trò',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 24,
                          child: Text(
                            'Ngày tham gia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 18,
                          child: Text(
                            'Trạng thái',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nội dung bảng
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF3B4E),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFFF3B4E),
                            onRefresh: _loadUsers,
                            child: users.isEmpty
                                ? ListView(
                                    children: [
                                      const SizedBox(height: 50),
                                      Center(
                                        child: Text(
                                          'Không tìm thấy tài khoản nào',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.only(bottom: 16),
                                    itemCount: users.length,
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      color:
                                          borderColor.withValues(alpha: 0.6),
                                    ),
                                    itemBuilder: (context, index) {
                                      return _buildUserTableRow(
                                        entry: users[index],
                                        isDark: isDark,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSummaryCard({
    required String filterKey,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String count,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isSelected = _roleFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _roleFilter =
              (_roleFilter == filterKey && filterKey != 'all')
                  ? 'all'
                  : filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF3B4E)
                : borderColor.withValues(alpha: 0.8),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTableRow({
    required _AdminUserEntry entry,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final u = entry.user;
    final isAdmin = u.getIsAdmin();
    final isActive = !u.isBanned;
    final contentOpacity = isActive ? 1.0 : 0.55;

    return InkWell(
      onTap: () => _showEditUserDialog(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            // Cột 1: Avatar + Username + Email
            Expanded(
              flex: 42,
              child: Opacity(
                opacity: contentOpacity,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFFF3B4E)
                          .withValues(alpha: 0.14),
                      backgroundImage:
                          (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                              ? NetworkImage(u.avatarUrl!)
                              : null,
                      child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                          ? Text(
                              u.getInitials(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF3B4E),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.username.isNotEmpty
                                ? u.username
                                : u.getDisplayName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            u.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cột 2: Vai trò (Admin / User badge)
            Expanded(
              flex: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFFFE4E6)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'User',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isAdmin
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ),
            ),

            // Cột 3: Ngày tham gia (dd/MM/yyyy)
            Expanded(
              flex: 24,
              child: Opacity(
                opacity: contentOpacity,
                child: Text(
                  _formatJoinDate(u.createdAt),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // Cột 4: Trạng thái (Hoạt động / Vô hiệu hóa + Switch)
            Expanded(
              flex: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isActive ? 'Hoạt động' : 'Vô hiệu hóa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? const Color(0xFFE11D48)
                          : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 26,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Switch(
                        value: isActive,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFFFF4B5C),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFFD1D5DB),
                        onChanged: (val) =>
                            _toggleUserActiveStatus(entry, val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUserEntry {
  final String docId;
  final User user;
  final Map<String, dynamic> rawData;

  const _AdminUserEntry({
    required this.docId,
    required this.user,
    required this.rawData,
  });
}
