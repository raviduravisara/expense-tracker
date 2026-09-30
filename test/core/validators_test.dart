import 'package:expense_tracker/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.title', () {
    test('rejects empty, too short and too long titles', () {
      expect(Validators.title(''), isNotNull);
      expect(Validators.title('   '), isNotNull);
      expect(Validators.title('a'), isNotNull);
      expect(Validators.title('a' * 51), isNotNull);
    });

    test('accepts a normal title', () {
      expect(Validators.title('Groceries'), isNull);
    });
  });

  group('Validators.amount', () {
    test('rejects empty, zero, malformed and huge amounts', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('0.00'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('1.234'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
      expect(Validators.amount('99999999'), isNotNull);
    });

    test('accepts positive amounts with up to two decimals', () {
      expect(Validators.amount('1250'), isNull);
      expect(Validators.amount('1250.5'), isNull);
      expect(Validators.amount('0.99'), isNull);
    });
  });

  test('Validators.note allows empty and limits length', () {
    expect(Validators.note(null), isNull);
    expect(Validators.note(''), isNull);
    expect(Validators.note('a' * 201), isNotNull);
  });

  test('Validators.email', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.email('me@example.com'), isNull);
  });

  test('Validators.password', () {
    expect(Validators.password(''), isNotNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
  });
}
