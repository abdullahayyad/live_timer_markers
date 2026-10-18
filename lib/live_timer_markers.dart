/// Live count-up and countdown timer markers for `google_maps_flutter`.
///
/// Create a [LiveTimerMarkersController], give it some [TimerMarker]s and
/// pass its value to `GoogleMap(markers: ...)`. The controller redraws the
/// labels once per second and only updates markers whose text changed.
library;

export 'src/live_timer_markers_controller.dart';
export 'src/timer_format.dart';
export 'src/timer_marker.dart';
export 'src/timer_marker_painter.dart';
export 'src/timer_marker_style.dart';
