class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    const pattern = r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(pattern).hasMatch(v.trim())) return 'Invalid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }
}
