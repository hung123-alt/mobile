import 'package:flutter/material.dart';

import '../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';

/// Trang Đặt mật khẩu mới — đích đến của deep link quên mật khẩu
/// (Phương án 1: `cinemahay24h://reset-password?oobCode=...&mode=resetPassword`).
///
/// Luồng:
/// 1. `DeepLinkService` bắt link trong email, tách `oobCode`, push tới đây.
/// 2. Trang gọi `verifyPasswordResetCode` để kiểm tra mã còn hiệu lực
///    và lấy email hiển thị (tránh user nhập nhầm tài khoản).
/// 3. User nhập mật khẩu mới → gọi `confirmPasswordReset` của Firebase Auth.
///    Mật khẩu mới chỉ nằm trong Auth (hash + salt), KHÔNG lưu plaintext
///    vào Firestore — khác với web NestJS dùng bcrypt + cột password_hash.
class ResetPasswordPage extends StatefulWidget {
  /// Mã một lần lấy từ deep link. Null khi mở trang thủ công.
  final String? oobCode;

  const ResetPasswordPage({super.key, this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthProvider _auth = AuthProvider.instance;

  bool _checking = true;
  bool _submitting = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _accountEmail;
  String? _linkError;

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = widget.oobCode?.trim() ?? '';
    if (code.isEmpty) {
      setState(() {
        _checking = false;
        _linkError =
            'Thiếu mã xác thực. Vui lòng mở lại liên kết trong email đặt lại mật khẩu.';
      });
      return;
    }
    final email = await _auth.verifyPasswordResetCode(code);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (email == null) {
        _linkError = _auth.errorMessage ??
            'Liên kết đã hết hạn hoặc đã được sử dụng. Vui lòng yêu cầu gửi lại email.';
      } else {
        _accountEmail = email;
      }
    });
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final code = widget.oobCode?.trim() ?? '';
    if (code.isEmpty) return;

    setState(() => _submitting = true);
    final ok = await _auth.confirmPasswordReset(
      oobCode: code,
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Đặt lại mật khẩu thành công! Hãy đăng nhập bằng mật khẩu mới.',
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      _goToLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _auth.errorMessage ?? 'Không thể đặt lại mật khẩu!',
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    TextInputAction action = TextInputAction.next,
    void Function(String)? onSubmitted,
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
        obscureText: obscure,
        textInputAction: action,
        onFieldSubmitted: onSubmitted != null
            ? (value) => onSubmitted(value)
            : null,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            onPressed: onToggle,
          ),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3D00), Color(0xFFFF5722)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Đặt mật khẩu mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_checking)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFFFF5722)),
                            SizedBox(height: 12),
                            Text(
                              'Đang kiểm tra liên kết...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_linkError != null)
                      Column(
                        children: [
                          const Icon(
                            Icons.link_off_rounded,
                            size: 48,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _linkError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.forgotPassword,
                                );
                              },
                              child: const Text(
                                'Gửi lại liên kết',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_accountEmail != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  'Tài khoản: $_accountEmail',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (_accountEmail != null)
                              const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                'Mật khẩu mới',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            _passwordField(
                              controller: _passwordController,
                              label: 'Mật khẩu mới',
                              hint: 'Ít nhất 6 ký tự',
                              obscure: _obscureNew,
                              onToggle: () => setState(
                                () => _obscureNew = !_obscureNew,
                              ),
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                'Xác nhận mật khẩu',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            _passwordField(
                              controller: _confirmController,
                              label: 'Xác nhận',
                              hint: 'Nhập lại mật khẩu mới',
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              validator: (v) => Validators.confirmPassword(
                                v,
                                _passwordController.text,
                              ),
                              action: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_submitting) _handleConfirm();
                              },
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF1A1A),
                                    Color(0xFFFF5722)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3D00)
                                        .withValues(alpha: 0.35),
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed:
                                    _submitting ? null : _handleConfirm,
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Đặt lại mật khẩu',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _goToLogin,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '< Quay lại đăng nhập',
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
}
