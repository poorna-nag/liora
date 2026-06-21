import 'package:flutter_test/flutter_test.dart';
import 'package:liora/core/services/notification_service.dart';

void main() {
  group('NotificationService.notificationIdFor', () {
    test('is stable for the same plan id', () {
      expect(
        NotificationService.notificationIdFor('plan-abc'),
        NotificationService.notificationIdFor('plan-abc'),
      );
    });

    test('differs for different plan ids', () {
      expect(
        NotificationService.notificationIdFor('plan-a'),
        isNot(NotificationService.notificationIdFor('plan-b')),
      );
    });

    test('is always a non-negative 32-bit int', () {
      for (final id in ['', 'x', 'a-very-long-uuid-like-string-0001', '🙂']) {
        final n = NotificationService.notificationIdFor(id);
        expect(n, greaterThanOrEqualTo(0));
        expect(n, lessThanOrEqualTo(0x7fffffff));
      }
    });
  });
}
