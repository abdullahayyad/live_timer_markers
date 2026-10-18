import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'timer_format.dart';
import 'timer_marker.dart';
import 'timer_marker_painter.dart';
import 'timer_marker_style.dart';

/// Keeps a set of [TimerMarker]s ticking and turns them into map [Marker]s.
///
/// The controller is a [ValueListenable], so you can rebuild the map
/// whenever the markers change:
///
/// ```dart
/// ValueListenableBuilder<Set<Marker>>(
///   valueListenable: controller,
///   builder: (context, markers, _) => GoogleMap(
///     initialCameraPosition: camera,
///     markers: markers,
///   ),
/// )
/// ```
///
/// Icons are cached by text and style: markers that show the same time
/// share one bitmap, and a marker whose text did not change keeps the same
/// icon object, so `GoogleMap` does not send it to the map again.
///
/// Call [dispose] when you no longer need the controller.
class LiveTimerMarkersController extends ChangeNotifier
    implements ValueListenable<Set<Marker>> {
  /// Creates a controller for [markers].
  ///
  /// [style] and [formatter] are used by markers that don't set their own.
  /// [pixelRatio] is the device pixel ratio the icons are drawn at; it
  /// defaults to the ratio of the app's main view. [clock] returns the
  /// current time and is mainly useful in tests.
  ///
  /// Unless [autoStart] is false, the labels start updating right away.
  LiveTimerMarkersController({
    Iterable<TimerMarker> markers = const <TimerMarker>[],
    this.style = const TimerMarkerStyle(),
    this.formatter = formatTimerLabel,
    double? pixelRatio,
    this.tickInterval = const Duration(seconds: 1),
    this.maxCachedIcons = 256,
    TimerMarkerPainter painter = const TimerMarkerPainter(),
    DateTime Function()? clock,
    bool autoStart = true,
  })  : assert(maxCachedIcons > 0),
        pixelRatio = pixelRatio ?? _mainViewPixelRatio(),
        _painter = painter,
        _clock = clock ?? DateTime.now,
        _running = autoStart {
    for (final marker in markers) {
      _entries[marker.markerId] = marker;
    }
    _changed();
  }

  /// The style of markers that don't set their own.
  final TimerMarkerStyle style;

  /// The label formatter of markers that don't set their own.
  final TimerLabelFormatter formatter;

  /// The device pixel ratio the icons are drawn at.
  final double pixelRatio;

  /// How often the labels are updated.
  final Duration tickInterval;

  /// The most rendered icons kept in memory. The least recently used ones
  /// are dropped first.
  final int maxCachedIcons;

  final TimerMarkerPainter _painter;
  final DateTime Function() _clock;
  final Map<MarkerId, TimerMarker> _entries = <MarkerId, TimerMarker>{};
  final Map<_IconKey, TimerMarkerIcon> _cache = <_IconKey, TimerMarkerIcon>{};
  final Map<_IconKey, Future<TimerMarkerIcon>> _pending =
      <_IconKey, Future<TimerMarkerIcon>>{};

  Set<Marker> _value = const <Marker>{};
  Timer? _timer;
  bool _running;
  bool _disposed = false;
  int _version = 0;
  Future<void>? _inFlight;
  bool _refreshAgain = false;

  /// The map markers, with their timer badges, for the current time.
  @override
  Set<Marker> get value => _value;

  /// The timer markers, in the order they were added.
  List<TimerMarker> get markers =>
      List<TimerMarker>.unmodifiable(_entries.values);

  /// Whether the labels update every [tickInterval].
  ///
  /// The controller only actually ticks while it has markers.
  bool get isRunning => _running;

  /// How many rendered icons are cached right now.
  @visibleForTesting
  int get cachedIconCount => _cache.length;

  /// Replaces all timer markers with [markers].
  void setMarkers(Iterable<TimerMarker> markers) {
    _entries.clear();
    for (final marker in markers) {
      _entries[marker.markerId] = marker;
    }
    _changed();
  }

  /// Adds [marker], or replaces the marker that has the same id.
  void addOrUpdate(TimerMarker marker) {
    _entries[marker.markerId] = marker;
    _changed();
  }

  /// Removes the marker with [markerId], if there is one.
  void remove(MarkerId markerId) {
    if (_entries.remove(markerId) != null) {
      _changed();
    }
  }

  /// Removes all markers.
  void clear() {
    if (_entries.isEmpty) {
      return;
    }
    _entries.clear();
    _changed();
  }

  /// Starts updating the labels every [tickInterval].
  void start() {
    _running = true;
    _syncTimer();
    _refreshAndReport();
  }

  /// Stops updating the labels. The markers stay as they are.
  void stop() {
    _running = false;
    _syncTimer();
  }

  /// Redraws the labels for the current time and updates [value].
  ///
  /// This runs on every tick, so you rarely need to call it yourself. The
  /// returned future completes once [value] is up to date.
  Future<void> refresh() {
    if (_disposed) {
      return Future<void>.value();
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      _refreshAgain = true;
      return inFlight;
    }
    return _inFlight = _refreshUntilCurrent();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _cache.clear();
    super.dispose();
  }

  void _changed() {
    _version++;
    _syncTimer();
    _refreshAndReport();
  }

  void _syncTimer() {
    final shouldTick = _running && !_disposed && _entries.isNotEmpty;
    if (shouldTick && _timer == null) {
      _timer = Timer.periodic(tickInterval, (_) => _refreshAndReport());
    } else if (!shouldTick && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _refreshAndReport() {
    refresh().catchError((Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'live_timer_markers',
          context: ErrorDescription('while updating timer markers'),
        ),
      );
    });
  }

  Future<void> _refreshUntilCurrent() async {
    try {
      do {
        _refreshAgain = false;
        await _refreshOnce();
      } while (_refreshAgain && !_disposed);
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _refreshOnce() async {
    final version = _version;
    final now = _clock();
    final entries = _entries.values.toList(growable: false);
    final icons = await Future.wait<TimerMarkerIcon>(
      entries.map((entry) => _iconFor(entry, now)),
    );
    if (_disposed || version != _version) {
      // The markers changed while the icons were drawn; the next pass will
      // publish the up-to-date set.
      return;
    }
    final next = <Marker>{
      for (var i = 0; i < icons.length; i++) _withIcon(entries[i], icons[i]),
    };
    if (setEquals(next, _value)) {
      return;
    }
    _value = Set<Marker>.unmodifiable(next);
    notifyListeners();
  }

  static Marker _withIcon(TimerMarker entry, TimerMarkerIcon icon) {
    return entry.marker.copyWith(
      iconParam: icon.bitmap,
      anchorParam: icon.anchor,
    );
  }

  Future<TimerMarkerIcon> _iconFor(TimerMarker entry, DateTime now) {
    final duration = entry.durationAt(now);
    final label = (entry.formatter ?? formatter)(duration);
    final markerStyle =
        entry.styleBuilder?.call(duration) ?? entry.style ?? style;
    final key = _IconKey(label, markerStyle);
    final cached = _cache.remove(key);
    if (cached != null) {
      // Re-insert to mark it as the most recently used icon.
      _cache[key] = cached;
      return Future<TimerMarkerIcon>.value(cached);
    }
    return _pending[key] ??= _render(key);
  }

  Future<TimerMarkerIcon> _render(_IconKey key) async {
    try {
      final icon = await _painter.render(
        key.label,
        key.style,
        pixelRatio: pixelRatio,
      );
      _cache[key] = icon;
      while (_cache.length > maxCachedIcons) {
        _cache.remove(_cache.keys.first);
      }
      return icon;
    } finally {
      _pending.remove(key);
    }
  }

  static double _mainViewPixelRatio() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    return view?.devicePixelRatio ?? 1.0;
  }
}

@immutable
class _IconKey {
  const _IconKey(this.label, this.style);

  final String label;
  final TimerMarkerStyle style;

  @override
  bool operator ==(Object other) {
    return other is _IconKey && other.label == label && other.style == style;
  }

  @override
  int get hashCode => Object.hash(label, style);
}
