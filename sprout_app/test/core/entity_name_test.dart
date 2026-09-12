import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/utils/entity_name.dart';

void main() {
  group('EntityName.isValid', () {
    test('accepts readable goal and account names', () {
      expect(EntityName.isValid('Cape Town trip'), isTrue);
      expect(EntityName.isValid('EasyEquities TFSA'), isTrue);
      expect(EntityName.isValid("Kid's college"), isTrue);
      expect(EntityName.isValid('Food & drink'), isTrue);
    });

    test('rejects empty, short, and symbol-only names', () {
      expect(EntityName.isValid(''), isFalse);
      expect(EntityName.isValid('A'), isFalse);
      expect(EntityName.isValid('12345'), isFalse);
      expect(EntityName.isValid(r'er34$34rre'), isFalse);
      expect(EntityName.isValid('@@@'), isFalse);
    });
  });
}
