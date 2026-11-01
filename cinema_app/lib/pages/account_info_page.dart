import 'package:flutter/material.dart';

import '../core/utils/validators.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/app_top_navbar.dart';

/// Trang Xem & Chỉnh sửa thông tin tài khoản + Đổi mật khẩu.
class AccountInfoPage extends StatefulWidget {
  final bool initialShowPasswordTab;

  const AccountInfoPage({
    super.key,
    this.initialShowPasswordTab = false,
  });

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final AuthProvider _auth = AuthProvider.instance;

  late bool _isPasswordTab;

  // Form keys
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Profile controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _bioController;
  String? _selectedAvatarUrl;
  String _selectedGender = '';

  // Password controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  static const List<String> _presetAvatars = [
    'https://api.dicebear.com/9.x/adventurer/png?seed=Felix&backgroundColor=ffdfbf',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Aneka&backgroundColor=c0aede',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Liam&backgroundColor=b6e3f4',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Sophia&backgroundColor=ffd5dc',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Leo&backgroundColor=d1d4f9',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Milo&backgroundColor=ffdfbf',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Zoe&backgroundColor=ffd5dc',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Noah&backgroundColor=b6e3f4',
  ];

  @override
  void initState() {
    super.initState();
    _isPasswordTab = widget.initialShowPasswordTab;
    final user = _auth.currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _birthDateController = TextEditingController(text: user?.birthDate ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _selectedAvatarUrl = user?.avatarUrl;
    _selectedGender = user?.gender ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(2000, 1, 1);

    final parts = _birthDateController.text.trim().split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null && y > 1900 && y <= now.year) {
        initialDate = DateTime(y, m, d);
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        _birthDateController.text = '$day/$month/$year';
      });
    }
  }

  void _showAvatarPickerSheet() {
    final urlController = TextEditingController(text: _selectedAvatarUrl ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn ảnh đại diện',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn nhanh từ bộ Avatar mẫu:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _presetAvatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final avatar = _presetAvatars[index];
                  final isCurrent = _selectedAvatarUrl == avatar;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarUrl = avatar);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFFFF4B5C)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person_rounded, size: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Hoặc dán đường dẫn URL ảnh của bạn:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'https://example.com/avatar.jpg',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_selectedAvatarUrl != null &&
                      _selectedAvatarUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _selectedAvatarUrl = null);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      label: const Text(
                        'Xoá ảnh',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B5C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final customUrl = urlController.text.trim();
                      setState(() {
                        _selectedAvatarUrl =
                            customUrl.isNotEmpty ? customUrl : null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Áp dụng URL'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    final ok = await _auth.updateProfile(
      username: _usernameController.text,
      avatarUrl: _selectedAvatarUrl,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      birthDate: _birthDateController.text,
      gender: _selectedGender,
      bio: _bioController.text,
    );

    if (!mounted) return;
    setState(() => _isSavingProfile = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật thông tin tài khoản thành công!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _auth.errorMessage ?? 'Không thể cập nhật thông tin tài khoản',
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);

    final ok = await _auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSavingPassword = false);

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đổi mật khẩu thành công!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.errorMessage ?? 'Đổi mật khẩu thất bại'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Chưa rõ';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _auth,
          builder: (context, _) {
            final user = _auth.currentUser;

            if (user == null) {
              return Column(
                children: [
                  const AppTopNavbar(showBackIfCanPop: true),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_circle_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Bạn chưa đăng nhập',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Vui lòng đăng nhập để xem và chỉnh sửa thông tin tài khoản.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4B5C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                );
                              },
                              child: const Text('Đăng nhập ngay'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                const AppTopNavbar(showBackIfCanPop: true),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        // ===== 1. CARD TỔNG QUAN TÀI KHOẢN & AVATAR =====
                        _buildHeaderCard(user, isDark),
                        const SizedBox(height: 18),

                        // ===== 2. THANH CHUYỂN TAB: THÔNG TIN CÁ NHÂN | ĐỔI MẬT KHẨU =====
                        _buildTabSwitcher(isDark),
                        const SizedBox(height: 18),

                        // ===== 3. NỘI DUNG FORM =====
                        if (!_isPasswordTab)
                          _buildProfileForm(user, isDark)
                        else
                          _buildPasswordForm(isDark),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(User user, bool isDark) {
    final isAdmin = user.getIsAdmin();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar kèm nút máy ảnh
          GestureDetector(
            onTap: _showAvatarPickerSheet,
            child: Stack(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
       
                    color: const Color(0xFFFF4B5C).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFFFF4B5C).withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _selectedAvatarUrl != null &&
                            _selectedAvatarUrl!.isNotEmpty
                        ? Image.network(
                            _selectedAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitialsAvatar(user),
                          )
                        : _buildInitialsAvatar(user),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B5C),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tên hiển thị
          Text(
            user.getDisplayName(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username} · ${user.email}',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          // Badges: Vai trò + Ngày tham gia
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFFFF4B5C).withValues(alpha: 0.14)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdmin
                          ? Icons.verified_user_rounded
                          : Icons.person_outline_rounded,
                      size: 14,
                      color: isAdmin
                          ? const Color(0xFFFF4B5C)
                          : const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAdmin ? 'Quản trị viên' : 'Thành viên',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? const Color(0xFFFF4B5C)
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262626)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tham gia: ${_formatDate(user.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(User user) {
    return Center(
      child: Text(
        user.getInitials(),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFF4B5C),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(bool isDark) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPasswordTab = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: !_isPasswordTab
                      ? const LinearGradient(
                          colors: [Color(0xFFFF1E27), Color(0xFFFF6A00)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        !_isPasswordTab ? FontWeight.bold : FontWeight.w600,
                    color: !_isPasswordTab
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPasswordTab = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: _isPasswordTab
                      ? const LinearGradient(
                          colors: [Color(0xFFFF1E27), Color(0xFFFF6A00)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        _isPasswordTab ? FontWeight.bold : FontWeight.w600,
                    color: _isPasswordTab
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(User user, bool isDark) {
    final genders = ['Nam', 'Nữ', 'Khác'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email (Chỉ xem)
            _buildLabel('Email (Không thể thay đổi)'),
            TextFormField(
              initialValue: user.email,
              readOnly: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'example@email.com',
                icon: Icons.mail_outline_rounded,
                suffixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tên đăng nhập (Username)
            _buildLabel('Tên đăng nhập *'),
            TextFormField(
              controller: _usernameController,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                if (v.trim().length < 3) {
                  return 'Tên đăng nhập tối thiểu 3 ký tự';
                }
                return null;
              },
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Nhập tên đăng nhập',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Họ và tên
            _buildLabel('Họ và tên'),
            TextFormField(
              controller: _fullNameController,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Thêm họ và tên đầy đủ của bạn',
                icon: Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // Số điện thoại
            _buildLabel('Số điện thoại'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final clean = v.trim();
                if (!RegExp(r'^[0-9+\-\s]{8,15}$').hasMatch(clean)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Thêm số điện thoại liên hệ',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // Ngày sinh
            _buildLabel('Ngày sinh'),
            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Chọn ngày sinh (dd/MM/yyyy)',
                icon: Icons.cake_outlined,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: Color(0xFFFF4B5C),
                  ),
                  onPressed: _pickBirthDate,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Giới tính
            _buildLabel('Giới tính'),
            Wrap(
              spacing: 10,
              children: genders.map((g) {
                final selected = _selectedGender == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: selected,
                  selectedColor:
                      const Color(0xFFFF4B5C).withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? const Color(0xFFFF4B5C)
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFFFF4B5C)
                        : (isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFE5E7EB)),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _selectedGender = val ? g : '';
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Giới thiệu bản thân (Bio)
            _buildLabel('Giới thiệu bản thân'),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Viết đôi dòng giới thiệu hoặc thể loại phim yêu thích...',
                icon: Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(height: 24),

            // Nút Lưu thông tin
            _buildGradientButton(
              text: 'Lưu thông tin',
              isLoading: _isSavingProfile,
              onPressed: _isSavingProfile ? null : _handleSaveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để bảo mật tài khoản, vui lòng nhập mật khẩu hiện tại trước khi thiết lập mật khẩu mới.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Mật khẩu hiện tại
            _buildLabel('Mật khẩu hiện tại *'),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPass,
              validator: (v) =>
                  Validators.required(v, fieldName: 'Mật khẩu hiện tại'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Nhập mật khẩu đang sử dụng',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () =>
                      setState(() => _showCurrentPass = !_showCurrentPass),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mật khẩu mới
            _buildLabel('Mật khẩu mới *'),
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNewPass,
              validator: (v) {
                final err = Validators.password(v);
                if (err != null) return err;
                if (v == _currentPasswordController.text) {
                  return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Ít nhất 6 ký tự',
                icon: Icons.vpn_key_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () => setState(() => _showNewPass = !_showNewPass),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Xác nhận mật khẩu mới
            _buildLabel('Xác nhận mật khẩu mới *'),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPass,
              validator: (v) =>
                  Validators.confirmPassword(v, _newPasswordController.text),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hintText: 'Nhập lại mật khẩu mới',
                icon: Icons.verified_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () =>
                      setState(() => _showConfirmPass = !_showConfirmPass),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút Cập nhật mật khẩu
            _buildGradientButton(
              text: 'Cập nhật mật khẩu',
              isLoading: _isSavingPassword,
              onPressed: _isSavingPassword ? null : _handleChangePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13.5,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF4B5C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1E27), Color(0xFFFF6A00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4B5C).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
