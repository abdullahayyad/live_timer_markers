/// Turns the time elapsed or left into the text drawn on a marker.
typedef TimerLabelFormatter = String Function(Duration duration);

/// Formats [duration] as `mm:ss` below one hour and `hh:mm:ss` from one hour.
///
/// Only whole seconds are shown, and negative durations are shown as `00:00`.
///
/// ```dart
/// formatTimerLabel(const Duration(minutes: 4, seconds: 27)); // 04:27
/// formatTimerLabel(const Duration(hours: 1, minutes: 2)); // 01:02:00
/// ```
String formatTimerLabel(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);
  final minutesAndSeconds = '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  if (hours == 0) {
    return minutesAndSeconds;
  }
  return '${_twoDigits(hours)}:$minutesAndSeconds';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
