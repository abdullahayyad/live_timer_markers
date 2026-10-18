import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_timer_markers/live_timer_markers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final start = DateTime(2026, 1, 1, 12);
  late DateTime now;

  setUp(() => now = start);

  Marker marker(String id) {
    return Marker(markerId: MarkerId(id), position: const LatLng(31.9, 35.2));
  }

  LiveTimerMarkersController createController(List<TimerMarker> markers) {
    final controller = LiveTimerMarkersController(
      markers: markers,
      pixelRatio: 2,
      clock: () => now,
      autoStart: false,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('turns timer markers into map markers with badge icons', () async {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
    ]);
    await controller.refresh();

    final result = controller.value.single;
    expect(result.markerId, const MarkerId('a'));
    expect(result.position, const LatLng(31.9, 35.2));
    expect(result.icon, isNot(BitmapDescriptor.defaultMarker));
    expect(result.anchor.dx, closeTo(0.5, 0.02));
  });

  test('keeps the same icon while the label does not change', () async {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
    ]);
    await controller.refresh();
    final first = controller.value.single.icon;

    now = start.add(const Duration(milliseconds: 600));
    await controller.refresh();
    expect(identical(controller.value.single.icon, first), isTrue);

    now = start.add(const Duration(seconds: 1));
    await controller.refresh();
    expect(identical(controller.value.single.icon, first), isFalse);
  });

  test('markers that show the same time share one icon', () async {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
      TimerMarker.countUp(marker: marker('b'), since: start),
    ]);
    await controller.refresh();

    final icons = controller.value.map((m) => m.icon).toList();
    expect(icons, hasLength(2));
    expect(identical(icons[0], icons[1]), isTrue);
    expect(controller.cachedIconCount, 1);
  });

  test('only notifies listeners when a label changes', () async {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
    ]);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.refresh();
    expect(notifications, 1);

    await controller.refresh();
    expect(notifications, 1);

    now = start.add(const Duration(seconds: 1));
    await controller.refresh();
    expect(notifications, 2);
  });

  test('passes the current duration to the style builder', () async {
    now = start.add(const Duration(minutes: 1, seconds: 30));
    final durations = <Duration>[];
    final controller = createController([
      TimerMarker.countUp(
        marker: marker('a'),
        since: start,
        styleBuilder: (duration) {
          durations.add(duration);
          return const TimerMarkerStyle(backgroundColor: Color(0xFFE53935));
        },
      ),
    ]);
    await controller.refresh();

    expect(durations, contains(const Duration(minutes: 1, seconds: 30)));
  });

  test('adds, updates and removes markers', () async {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
    ]);
    await controller.refresh();
    expect(controller.value, hasLength(1));

    controller.addOrUpdate(
      TimerMarker.countDown(
        marker: marker('b'),
        until: start.add(const Duration(minutes: 5)),
      ),
    );
    await controller.refresh();
    expect(controller.value.map((m) => m.markerId.value), ['a', 'b']);
    expect(controller.markers, hasLength(2));

    controller.remove(const MarkerId('a'));
    await controller.refresh();
    expect(controller.value.map((m) => m.markerId.value), ['b']);

    controller.clear();
    await controller.refresh();
    expect(controller.value, isEmpty);
  });

  test('replaces all markers with setMarkers', () async {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
    ]);
    controller.setMarkers([
      TimerMarker.countUp(marker: marker('c'), since: start),
      TimerMarker.countUp(marker: marker('d'), since: start),
    ]);
    await controller.refresh();

    expect(controller.value.map((m) => m.markerId.value), ['c', 'd']);
  });

  test('start and stop switch the ticking on and off', () {
    final controller = createController([
      TimerMarker.countUp(marker: marker('a'), since: start),
    ]);
    expect(controller.isRunning, isFalse);

    controller.start();
    expect(controller.isRunning, isTrue);

    controller.stop();
    expect(controller.isRunning, isFalse);
  });

  test('does nothing after it is disposed', () async {
    final controller = LiveTimerMarkersController(
      markers: [TimerMarker.countUp(marker: marker('a'), since: start)],
      pixelRatio: 2,
      clock: () => now,
      autoStart: false,
    );
    controller.dispose();

    await controller.refresh();
    expect(controller.value, isEmpty);
  });
}
