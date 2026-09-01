import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/utils/unique_name.dart';

void main() {
  group('UniqueName.isTaken', () {
    const existing = [
      (id: '1', name: 'Emergency Fund'),
      (id: '2', name: 'Vacation'),
    ];

    test('detects duplicate case-insensitively', () {
      expect(
        UniqueName.isTaken(
          existing: existing,
          candidateName: 'emergency fund',
        ),
        isTrue,
      );
    });

    test('excludes self when updating', () {
      expect(
        UniqueName.isTaken(
          existing: existing,
          candidateName: 'Emergency Fund',
          excludeId: '1',
        ),
        isFalse,
      );
    });
  });
}
