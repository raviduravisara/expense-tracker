abstract final class Validators {
  static const titleMaxLength = 50;
  static const noteMaxLength = 200;
  static const maxAmount = 10000000.0;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter a title';
    if (text.length < 2) return 'Title must be at least 2 characters';
    if (text.length > titleMaxLength) {
      return 'Title must be $titleMaxLength characters or less';
    }
    return null;
  }

  static String? amount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter an amount';
    if (!_amountPattern.hasMatch(text)) return 'Enter a valid amount (e.g. 1250.50)';
    final amount = double.parse(text);
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > maxAmount) return 'Amount is too large';
    return null;
  }

  static String? note(String? value) {
    if ((value?.trim().length ?? 0) > noteMaxLength) {
      return 'Note must be $noteMaxLength characters or less';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your email';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
