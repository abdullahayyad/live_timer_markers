import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_timer_markers/live_timer_markers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const painter = TimerMarkerPainter();
  const style = TimerMarkerStyle();

  test('renders a PNG with the right number of pixels', () async {
    final icon = await painter.render('04:27', style, pixelRatio: 2);

    final pixels = _pngSize(icon.pngBytes);
    expect(pixels.width, icon.logicalSize.width * 2);
    expect(pixels.height, icon.logicalSize.height * 2);
    expect(icon.label, '04:27');
    expect(icon.pixelRatio, 2);
  });

  test('measures the same size it renders', () async {
    final measured = painter.measure('12:34', style);
    final icon = await painter.render('12:34', style);

    expect(icon.logicalSize.width, closeTo(measured.width, 1));
    expect(icon.logicalSize.height, closeTo(measured.height, 1));
  });

  test('longer labels make wider badges', () {
    final short = painter.measure('04:27', style);
    final long = painter.measure('01:04:27', style);

    expect(long.width, greaterThan(short.width));
    expect(long.height, short.height);
  });

  test('anchors the icon at the tip of the pointer', () async {
    final icon = await painter.render('04:27', style, pixelRatio: 3);

    expect(icon.anchor.dx, closeTo(0.5, 0.02));
    expect(icon.anchor.dy, greaterThan(0.5));
    expect(icon.anchor.dy, lessThan(1));
  });

  test('a badge without a pointer is shorter', () {
    const noPointer = TimerMarkerStyle(pointerSize: Size.zero);

    final withPointer = painter.measure('04:27', style);
    final without = painter.measure('04:27', noPointer);

    expect(without.height, lessThan(withPointer.height));
  });

  test('styles with the same values are equal', () {
    const a = TimerMarkerStyle(backgroundColor: Color(0xFF1E88E5));
    final b = const TimerMarkerStyle().copyWith(
      backgroundColor: const Color(0xFF1E88E5),
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const TimerMarkerStyle()));
  });
}

/// Reads the width and height from a PNG header.
Size _pngSize(Uint8List bytes) {
  expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  final header = ByteData.sublistView(bytes);
  return Size(
    header.getUint32(16).toDouble(),
    header.getUint32(20).toDouble(),
  );
}
