import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isKiitEmail(String email) => email.trim().toLowerCase().endsWith('@${AppConstants.allowedEmailDomain}');

  static String? kiitEmail(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) return 'Enter your KIIT email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email';
    if (!isKiitEmail(v)) return 'Use your @${AppConstants.allowedEmailDomain} email';
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < AppConstants.minPasswordLength) {
      return 'At least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? name(String? value) => (value?.trim().length ?? 0) < 2 ? 'Enter your full name' : null;

  static String? optionalPhone(String? value) {
    final v = value?.replaceAll(RegExp(r'[\s-]'), '') ?? '';
    if (v.isEmpty) return null;
    return RegExp(r'^\+?\d{10,13}$').hasMatch(v) ? null : 'Enter a valid phone number';
  }
}
