import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'timer_marker_style.dart';

/// A rendered timer badge, ready to be used as a marker icon.
class TimerMarkerIcon {
  /// Creates a rendered icon. Usually made by [TimerMarkerPainter.render].
  TimerMarkerIcon({
    required this.label,
    required this.pngBytes,
    required this.logicalSize,
    required this.pixelRatio,
    required this.anchor,
  }) : bitmap = BitmapDescriptor.bytes(pngBytes, imagePixelRatio: pixelRatio);

  /// The text drawn on the badge.
  final String label;

  /// The badge as a PNG image, [pixelRatio] times larger than [logicalSize].
  final Uint8List pngBytes;

  /// The size of the image in logical pixels.
  final Size logicalSize;

  /// How many physical pixels the image has per logical pixel.
  final double pixelRatio;

  /// The point of the image that sits on the marker's position.
  ///
  /// It goes from `(0, 0)` at the top left to `(1, 1)` at the bottom right.
  /// Pass it to `Marker.anchor`.
  final Offset anchor;

  /// [pngBytes] wrapped as a map icon.
  ///
  /// Reuse this instance: when a marker keeps the same icon object,
  /// `GoogleMap` knows the marker did not change and skips updating it.
  final BitmapDescriptor bitmap;
}

/// Draws timer badges and turns them into marker icons.
///
/// You don't need this directly when you use the controller, which renders
/// and caches icons for you. It is public so you can draw a badge yourself,
/// for example for a static marker or a map legend.
class TimerMarkerPainter {
  /// Creates a painter.
  const TimerMarkerPainter();

  /// The size, in logical pixels, of the image for [label] in [style].
  Size measure(String label, TimerMarkerStyle style) {
    final text = _layoutText(label, style);
    final size = _BadgeLayout(text, style).imageSize;
    text.dispose();
    return size;
  }

  /// Renders the badge for [label] in [style] as a PNG image.
  ///
  /// [pixelRatio] is the device pixel ratio. Use the screen's ratio so the
  /// icon looks sharp, for example `MediaQuery.devicePixelRatioOf(context)`.
  Future<TimerMarkerIcon> render(
    String label,
    TimerMarkerStyle style, {
    double pixelRatio = 1,
  }) async {
    assert(pixelRatio > 0);
    final text = _layoutText(label, style);
    final layout = _BadgeLayout(text, style);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    _paintBadge(canvas, layout, text, style);
    text.dispose();

    final picture = recorder.endRecording();
    final width = (layout.imageSize.width * pixelRatio).ceil();
    final height = (layout.imageSize.height * pixelRatio).ceil();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Could not encode the timer marker icon as PNG.');
      }
      final logicalSize = Size(width / pixelRatio, height / pixelRatio);
      return TimerMarkerIcon(
        label: label,
        pngBytes: Uint8List.sublistView(data),
        logicalSize: logicalSize,
        pixelRatio: pixelRatio,
        anchor: Offset(
          layout.tip.dx / logicalSize.width,
          layout.tip.dy / logicalSize.height,
        ),
      );
    } finally {
      image.dispose();
    }
  }

  TextPainter _layoutText(String label, TimerMarkerStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: style.textColor,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          fontFamily: style.fontFamily,
          // Equal-width digits, so the badge doesn't change size every second.
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    painter.layout();
    return painter;
  }

  void _paintBadge(
    Canvas canvas,
    _BadgeLayout layout,
    TextPainter text,
    TimerMarkerStyle style,
  ) {
    final path = _badgePath(layout.badge, style.borderRadius, layout.pointer);
    if (style.shadowBlur > 0) {
      final shadow = Paint()
        ..color = style.shadowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.shadowBlur);
      canvas.drawPath(path.shift(const Offset(0, 1)), shadow);
    }
    canvas.drawPath(path, Paint()..color = style.backgroundColor);
    final borderColor = style.borderColor;
    if (borderColor != null && style.borderWidth > 0) {
      final border = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.borderWidth;
      canvas.drawPath(path, border);
    }
    text.paint(canvas, layout.textOffset);
  }

  Path _badgePath(Rect rect, double borderRadius, Size pointer) {
    // Keep the corners off the straight bottom edge the pointer sits on.
    final straightWidth = rect.width - pointer.width;
    final maxRadius = math.min(rect.height / 2, straightWidth / 2);
    final r = math.max(0.0, math.min(borderRadius, maxRadius));
    final radius = Radius.circular(r);
    final path = Path()
      ..moveTo(rect.left + r, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: radius)
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: radius);
    if (pointer.width > 0 && pointer.height > 0) {
      final center = rect.center.dx;
      path
        ..lineTo(center + pointer.width / 2, rect.bottom)
        ..lineTo(center, rect.bottom + pointer.height)
        ..lineTo(center - pointer.width / 2, rect.bottom);
    }
    path
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: radius)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: radius)
      ..close();
    return path;
  }
}

/// Where everything goes inside the image, in logical pixels.
class _BadgeLayout {
  factory _BadgeLayout(TextPainter text, TimerMarkerStyle style) {
    final padding = style.padding;
    final pointer = style.pointerSize.width > 0 && style.pointerSize.height > 0
        ? style.pointerSize
        : Size.zero;
    // Leave room around the badge so the shadow and the anti-aliased edges
    // are not cut off.
    final margin = style.shadowBlur > 0 ? style.shadowBlur * 3 + 1 : 1.0;
    final badge = Rect.fromLTWH(
      margin,
      margin,
      text.width + padding.horizontal,
      text.height + padding.vertical,
    );
    return _BadgeLayout._(
      badge: badge,
      pointer: pointer,
      textOffset: Offset(badge.left + padding.left, badge.top + padding.top),
      tip: Offset(badge.center.dx, badge.bottom + pointer.height),
      imageSize: Size(
        badge.width + margin * 2,
        badge.height + pointer.height + margin * 2,
      ),
    );
  }

  const _BadgeLayout._({
    required this.badge,
    required this.pointer,
    required this.textOffset,
    required this.tip,
    required this.imageSize,
  });

  final Rect badge;
  final Size pointer;
  final Offset textOffset;
  final Offset tip;
  final Size imageSize;
}
