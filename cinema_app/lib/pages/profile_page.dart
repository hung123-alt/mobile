import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/app_top_navbar.dart';

/// Trang Tài khoản (Component 5 trong ảnh mẫu).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AuthProvider.instance,
          builder: (context, _) {
            final auth = AuthProvider.instance;
            final user = auth.currentUser;

            return Column(
              children: [
                // Top App Bar dùng chung
                const AppTopNavbar(),
                const SizedBox(height: 10),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Card thông tin cá nhân (bấm vào để mở trang Thông tin tài khoản)
                        GestureDetector(
                          onTap: () {
                            if (user != null) {
                              Navigator.pushNamed(context, AppRoutes.accountInfo);
                            } else {
                              Navigator.pushNamed(context, AppRoutes.login);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Avatar tròn
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4B5C).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                        ? Image.network(
                                            user.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.pets_rounded, color: Color(0xFFFF4B5C), size: 28),
                                          )
                                        : const Icon(Icons.pets_rounded, color: Color(0xFFFF4B5C), size: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Tên và email
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.getDisplayName() ?? 'Khách (Chưa đăng nhập)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user?.email ?? 'Bấm đăng nhập để trải nghiệm đầy đủ',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (user == null)
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                                    child: const Text('Đăng nhập', style: TextStyle(color: Color(0xFFFF4B5C))),
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: Color(0xFF9CA3AF),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Menu Options Card
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingItem(
                                icon: Icons.access_time_rounded,
                                title: 'Lịch sử xem',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lịch sử xem phim')),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 52),
                              _buildSettingItem(
                                icon: Icons.favorite_outline_rounded,
                                title: 'Phim yêu thích',
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.favorite);
                                },
                              ),
                              const Divider(height: 1, indent: 52),
                              _buildSettingItem(
                                icon: Icons.manage_accounts_outlined,
                                title: 'Thông tin cá nhân / Cài đặt',
                                onTap: () {
                                  if (user != null) {
                                    Navigator.pushNamed(context, AppRoutes.accountInfo);
                                  } else {
                                    Navigator.pushNamed(context, AppRoutes.login);
                                  }
                                },
                              ),
                              const Divider(height: 1, indent: 52),
                              // Chế độ tối có Switch button màu đỏ
                              ListenableBuilder(
                                listenable: ThemeProvider.instance,
                                builder: (context, _) {
                                  final isDarkActive = ThemeProvider.instance.isDarkMode;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.nightlight_outlined,
                                          size: 22,
                                          color: Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(
                                          child: Text(
                                            'Chế độ tối',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Switch(
                                          value: isDarkActive,
                                          activeThumbColor: const Color(0xFFFF4B5C),
                                          activeTrackColor: const Color(0xFFFF4B5C).withValues(alpha: 0.4),
                                          onChanged: (val) {
                                            ThemeProvider.instance.setDarkMode(val);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 52),
                              _buildSettingItem(
                                icon: Icons.logout_rounded,
                                title: 'Đăng xuất',
                                isDestructive: true,
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xác nhận đăng xuất'),
                                      content: const Text('Bạn có muốn đăng xuất khỏi tài khoản không?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF4B5C),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Đăng xuất'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await AuthProvider.instance.logout();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.login,
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 22,
        color: isDestructive ? const Color(0xFFFF4B5C) : const Color(0xFF6B7280),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFFF4B5C) : null,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFF9CA3AF),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
