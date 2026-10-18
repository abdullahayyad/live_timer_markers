import 'package:flutter_test/flutter_test.dart';
import 'package:live_timer_markers/live_timer_markers.dart';

void main() {
  group('formatTimerLabel', () {
    test('shows minutes and seconds below one hour', () {
      expect(formatTimerLabel(Duration.zero), '00:00');
      expect(formatTimerLabel(const Duration(seconds: 7)), '00:07');
      expect(
        formatTimerLabel(const Duration(minutes: 4, seconds: 27)),
        '04:27',
      );
      expect(
        formatTimerLabel(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
    });

    test('adds hours from one hour', () {
      expect(formatTimerLabel(const Duration(hours: 1)), '01:00:00');
      expect(
        formatTimerLabel(const Duration(hours: 12, minutes: 5, seconds: 9)),
        '12:05:09',
      );
      expect(formatTimerLabel(const Duration(hours: 100)), '100:00:00');
    });

    test('shows whole seconds only', () {
      expect(
        formatTimerLabel(const Duration(seconds: 3, milliseconds: 999)),
        '00:03',
      );
    });

    test('shows negative durations as zero', () {
      expect(formatTimerLabel(const Duration(seconds: -5)), '00:00');
    });
  });
}
