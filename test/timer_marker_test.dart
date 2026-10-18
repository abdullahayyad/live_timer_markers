import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_timer_markers/live_timer_markers.dart';

void main() {
  final start = DateTime(2026, 1, 1, 12);
  const marker = Marker(markerId: MarkerId('order'));

  group('TimerMarker.countUp', () {
    final timer = TimerMarker.countUp(marker: marker, since: start);

    test('counts the time elapsed since the start', () {
      final now = start.add(const Duration(minutes: 4, seconds: 27));
      expect(timer.durationAt(now), const Duration(minutes: 4, seconds: 27));
    });

    test('rounds down to whole seconds', () {
      final now = start.add(const Duration(seconds: 2, milliseconds: 900));
      expect(timer.durationAt(now), const Duration(seconds: 2));
    });

    test('shows zero before the start', () {
      final now = start.subtract(const Duration(seconds: 30));
      expect(timer.durationAt(now), Duration.zero);
    });

    test('keeps the marker id', () {
      expect(timer.markerId, const MarkerId('order'));
      expect(timer.direction, TimerDirection.countUp);
    });
  });

  group('TimerMarker.countDown', () {
    final end = start.add(const Duration(minutes: 10));
    final timer = TimerMarker.countDown(marker: marker, until: end);

    test('counts the time left until the end', () {
      expect(timer.durationAt(start), const Duration(minutes: 10));
      expect(timer.direction, TimerDirection.countDown);
    });

    test('rounds up to whole seconds', () {
      final now = end.subtract(const Duration(milliseconds: 1500));
      expect(timer.durationAt(now), const Duration(seconds: 2));
    });

    test('stops at zero', () {
      expect(timer.durationAt(end), Duration.zero);
      final later = end.add(const Duration(minutes: 3));
      expect(timer.durationAt(later), Duration.zero);
    });
  });
}
