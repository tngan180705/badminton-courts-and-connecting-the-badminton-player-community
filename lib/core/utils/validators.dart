class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Vui lòng nhập số điện thoại";
    if (!RegExp(r'^\d{10}$').hasMatch(value))
      return "Số điện thoại phải có 10 chữ số";
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Vui lòng nhập email";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return "Email không hợp lệ";
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Vui lòng nhập mật khẩu";
    if (value.length < 6) return "Mật khẩu phải ít nhất 6 ký tự";
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return "Vui lòng nhập họ và tên";
    return null;
  }
}
