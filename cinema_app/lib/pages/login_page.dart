import 'package:flutter/material.dart';

import '../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

/// Trang Đăng nhập và Đăng ký (thiết kế chuẩn theo mẫu).
///
/// Hỗ trợ chuyển đổi mượt mà giữa 2 tab "Đăng nhập" và "Đăng ký".
class LoginPage extends StatefulWidget {
  final bool initialIsRegister;

  const LoginPage({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool _isRegister;

  // Controllers
  final _emailOrUserLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  // Form keys
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // State
  bool _isPasswordLoginVisible = false;
  bool _isPasswordRegisterVisible = false;
  bool _isLoading = false;

  final AuthProvider _auth = AuthProvider.instance;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _emailOrUserLoginController.dispose();
    _passwordLoginController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _auth.login(
      identifier: _emailOrUserLoginController.text,
      password: _passwordLoginController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chào mừng trở lại, ${_auth.currentUser?.getDisplayName()}!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      final msg = _auth.errorMessage ?? 'Đăng nhập thất bại. Vui lòng thử lại!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _auth.register(
      username: _registerUsernameController.text,
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký thành công! Chào mừng ${_auth.currentUser?.getDisplayName()}'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      final msg = _auth.errorMessage ?? 'Đăng ký thất bại. Vui lòng thử lại!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailOrUserLoginController.text.contains('@')
          ? _emailOrUserLoginController.text.trim()
          : '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Color(0xFFFF5722)),
              SizedBox(width: 8),
              Text('Quên mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập email đã đăng ký của bạn. Chúng tôi sẽ gửi liên kết đặt lại mật khẩu qua email.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@email.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSending = true);
                      final ok = await _auth.sendPasswordReset(resetEmailController.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Đã gửi email đặt lại mật khẩu! Vui lòng kiểm tra hộp thư.'
                                : 'Không thể gửi email đặt lại mật khẩu.'),
                            backgroundColor: ok ? Colors.green[700] : Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gửi email'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== 1. LOGO TIÊU ĐỀ =====
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'PHIM HAY',
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          TextSpan(
                            text: ' 24H',
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== 2. THANH CHUYỂN TAB ĐĂNG NHẬP / ĐĂNG KÝ =====
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Tab Đăng nhập
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_isRegister) {
                                  setState(() => _isRegister = false);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  gradient: !_isRegister
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFF3D00), Color(0xFFFF5722)],
                                        )
                                      : null,
                                  color: !_isRegister ? const Color(0xFFFF5722) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: !_isRegister ? Colors.white : const Color(0xFF1F2937),
                                    fontSize: 14,
                                    fontWeight: !_isRegister ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Tab Đăng ký
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_isRegister) {
                                  setState(() => _isRegister = true);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  gradient: _isRegister
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFF3D00), Color(0xFFFF5722)],
                                        )
                                      : null,
                                  color: _isRegister ? const Color(0xFFFF5722) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Đăng ký',
                                  style: TextStyle(
                                    color: _isRegister ? Colors.white : const Color(0xFF1F2937),
                                    fontSize: 14,
                                    fontWeight: _isRegister ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ===== 3. DÒNG CHÚ THÍCH PHỤ =====
                    Text(
                      !_isRegister
                          ? 'Chào mừng trở lại! Đăng nhập để tiếp tục xem phim'
                          : 'Tạo tài khoản miễn phí, thưởng thức phim không giới hạn.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== 4. NỘI DUNG FORM =====
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState:
                          !_isRegister ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      firstChild: _buildLoginForm(),
                      secondChild: _buildRegisterForm(),
                    ),
                    const SizedBox(height: 16),

                    // ===== 5. NÚT QUAY LẠI TRANG CHỦ =====
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '< Quay lại trang chủ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Form Đăng nhập
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Email'),
          _buildInputField(
            controller: _emailOrUserLoginController,
            hintText: 'example@email.com',
            icon: Icons.mail_outline_rounded,
            validator: (v) => Validators.required(v, fieldName: 'Email hoặc Tên đăng nhập'),
          ),
          const SizedBox(height: 14),
          _buildFieldLabel('Mật khẩu'),
          _buildInputField(
            controller: _passwordLoginController,
            hintText: 'Nhập mật khẩu',
            icon: Icons.lock_outline_rounded,
            obscureText: !_isPasswordLoginVisible,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordLoginVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () {
                setState(() => _isPasswordLoginVisible = !_isPasswordLoginVisible);
              },
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _showForgotPasswordDialog,
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            text: 'Đăng Nhập',
            onPressed: _isLoading ? null : _handleLogin,
          ),
        ],
      ),
    );
  }

  /// Form Đăng ký
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Tên đăng nhập'),
          _buildInputField(
            controller: _registerUsernameController,
            hintText: 'example@email.com',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
              if (v.trim().length < 3) return 'Tên đăng nhập tối thiểu 3 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildFieldLabel('Email'),
          _buildInputField(
            controller: _registerEmailController,
            hintText: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            icon: Icons.mail_outline_rounded,
            validator: Validators.email,
          ),
          const SizedBox(height: 14),
          _buildFieldLabel('Mật khẩu'),
          _buildInputField(
            controller: _registerPasswordController,
            hintText: 'Ít nhất 8 ký tự',
            icon: Icons.lock_outline_rounded,
            obscureText: !_isPasswordRegisterVisible,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
              if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordRegisterVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () {
                setState(() => _isPasswordRegisterVisible = !_isPasswordRegisterVisible);
              },
            ),
          ),
          const SizedBox(height: 22),
          _buildPrimaryButton(
            text: 'Đăng Ký',
            onPressed: _isLoading ? null : _handleRegister,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13.5,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1A1A), Color(0xFFFF5722)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D00).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: _isLoading
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
