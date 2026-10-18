import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'timer_format.dart';
import 'timer_marker_style.dart';

/// Whether a timer counts up from a start time or down to an end time.
enum TimerDirection {
  /// Shows the time elapsed since [TimerMarker.time], for example how long
  /// an order has been waiting.
  countUp,

  /// Shows the time left until [TimerMarker.time], for example until a
  /// pickup. Stops at zero.
  countDown,
}

/// Picks a style from the timer's current duration, for example to turn a
/// marker red once it has waited too long.
typedef TimerStyleBuilder = TimerMarkerStyle Function(Duration duration);

/// A map marker that shows a live timer instead of a pin.
@immutable
class TimerMarker {
  /// Creates a timer marker.
  ///
  /// [TimerMarker.countUp] and [TimerMarker.countDown] read more clearly.
  const TimerMarker({
    required this.marker,
    required this.time,
    this.direction = TimerDirection.countUp,
    this.style,
    this.styleBuilder,
    this.formatter,
  });

  /// A marker that shows the time elapsed since [since].
  const TimerMarker.countUp({
    required Marker marker,
    required DateTime since,
    TimerMarkerStyle? style,
    TimerStyleBuilder? styleBuilder,
    TimerLabelFormatter? formatter,
  }) : this(
          marker: marker,
          time: since,
          style: style,
          styleBuilder: styleBuilder,
          formatter: formatter,
        );

  /// A marker that shows the time left until [until], stopping at zero.
  const TimerMarker.countDown({
    required Marker marker,
    required DateTime until,
    TimerMarkerStyle? style,
    TimerStyleBuilder? styleBuilder,
    TimerLabelFormatter? formatter,
  }) : this(
          marker: marker,
          time: until,
          direction: TimerDirection.countDown,
          style: style,
          styleBuilder: styleBuilder,
          formatter: formatter,
        );

  /// The marker to show.
  ///
  /// Its id, position, `onTap` and other settings are kept. Its icon and
  /// anchor are replaced by the timer badge.
  final Marker marker;

  /// The start time when counting up, or the end time when counting down.
  final DateTime time;

  /// Whether the timer counts up or down.
  final TimerDirection direction;

  /// The style of this marker. Falls back to the controller's style.
  final TimerMarkerStyle? style;

  /// Picks a style from the current duration. Takes precedence over [style].
  final TimerStyleBuilder? styleBuilder;

  /// Formats the label of this marker. Falls back to the controller's
  /// formatter, which is [formatTimerLabel] by default.
  final TimerLabelFormatter? formatter;

  /// The id of [marker].
  MarkerId get markerId => marker.markerId;

  /// The duration to show at [now], in whole seconds.
  ///
  /// Counting up, this is the time elapsed since [time], rounded down.
  /// Counting down, it is the time left until [time], rounded up, so the
  /// label reaches `00:00` exactly when the time is up. It is never negative.
  Duration durationAt(DateTime now) {
    return switch (direction) {
      TimerDirection.countUp => _roundDown(now.difference(time)),
      TimerDirection.countDown => _roundUp(time.difference(now)),
    };
  }

  static Duration _roundDown(Duration duration) {
    if (duration.isNegative) {
      return Duration.zero;
    }
    return Duration(seconds: duration.inSeconds);
  }

  static Duration _roundUp(Duration duration) {
    if (duration <= Duration.zero) {
      return Duration.zero;
    }
    final micros = duration.inMicroseconds;
    final seconds = (micros / Duration.microsecondsPerSecond).ceil();
    return Duration(seconds: seconds);
  }
}
