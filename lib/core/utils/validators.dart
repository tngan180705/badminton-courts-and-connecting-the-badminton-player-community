class Validators {
  /// 📱 SĐT Việt Nam (10 số, bắt đầu 03/05/07/08/09)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập số điện thoại";
    }

    final phone = value.trim();

    final regex = RegExp(r'^(03|05|07|08|09)\d{8}$');

    if (!regex.hasMatch(phone)) {
      return "Số điện thoại không hợp lệ (VD: 09xxxxxxxx)";
    }

    return null;
  }

  /// 📧 Email chuẩn RFC đơn giản
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập email";
    }

    final email = value.trim();

    final regex = RegExp(
      r'^[\w\.-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
    );

    if (!regex.hasMatch(email)) {
      return "Email không hợp lệ";
    }

    return null;
  }

  /// 🔐 Password mạnh hơn (Firebase-friendly)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Vui lòng nhập mật khẩu";
    }

    if (value.length < 8) {
      return "Mật khẩu phải từ 8 ký tự trở lên";
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Mật khẩu phải có ít nhất 1 chữ in hoa";
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Mật khẩu phải có ít nhất 1 chữ thường";
    }

    if (!RegExp(r'\d').hasMatch(value)) {
      return "Mật khẩu phải có ít nhất 1 chữ số";
    }

    return null;
  }

  /// 👤 Họ tên (không số, không ký tự đặc biệt)
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Vui lòng nhập họ và tên";
    }

    final name = value.trim();

    if (name.length < 2) {
      return "Họ tên quá ngắn";
    }

    final regex = RegExp(r"^[\p{L}\s]+$", unicode: true);

    if (!regex.hasMatch(name)) {
      return "Họ tên không được chứa số hoặc ký tự đặc biệt";
    }

    return null;
  }
}
