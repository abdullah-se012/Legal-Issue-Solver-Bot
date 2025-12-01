// lib/utils/validators.dart
class Validators {
  // RFC-5322-ish email regex (practical, not perfect)
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  // Name: 2..60 characters, letters, spaces, hyphen, apostrophe
  static final RegExp _nameRegExp = RegExp(r"^[A-Za-z\s'-]{2,60}$");

  // Password rules: min 8 chars, at least one upper, one lower, one digit and one special
  static final RegExp _passwordStrong = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~^%()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (!_nameRegExp.hasMatch(value.trim())) return 'Enter a real name (2-60 letters)';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!_passwordStrong.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number and special character';
    }
    return null;
  }

  static String? confirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) return 'Confirm your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  // For a quick (looser) strength check: returns 0..4
  static int passwordStrengthScore(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~^%()_\-+=\[\]{};:"\\|,.<>\/?]').hasMatch(password)) score++;
    return score;
  }
}
