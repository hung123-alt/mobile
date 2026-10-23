/// Hàm kiểm tra dữ liệu đầu vào của form.
///
/// Theo yêu cầu tuần 8: "Tách phần kiểm tra dữ liệu ra thành một
/// phương thức riêng. Sau đó gọi thực hiện phương thức mỗi khi
/// Submit Form (xem sự kiện onSubmitted)."
class Validators {
  Validators._();

  /// Kiểm tra rỗng
  static String? required(String? value, {String fieldName = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  /// Kiểm tra email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Kiểm tra mật khẩu tối thiểu 6 ký tự
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra xác nhận mật khẩu
  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != original) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Kiểm tra số
  static String? number(String? value, {String fieldName = 'Giá trị'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    if (num.tryParse(value.trim()) == null) {
      return '$fieldName phải là số';
    }
    return null;
  }

  /// Kiểm tra điểm trong khoảng 1-10
  static String? rating(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng chấm điểm';
    }
    final score = int.tryParse(value.trim());
    if (score == null) {
      return 'Điểm phải là số';
    }
    if (score < 1 || score > 10) {
      return 'Điểm phải từ 1 đến 10';
    }
    return null;
  }

  /// Gom nhiều lỗi thành 1 chuỗi
  static String? merge(List<String?> errors) {
    final list = errors.where((e) => e != null).toList();
    if (list.isEmpty) return null;
    return list.join('\n');
  }
}
