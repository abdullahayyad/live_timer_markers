import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_timer_markers/live_timer_markers.dart';

void main() {
  runApp(const MaterialApp(home: TimerMapPage()));
}

/// A map with three live timers: two orders waiting and one pickup.
class TimerMapPage extends StatefulWidget {
  /// Creates the demo page.
  const TimerMapPage({super.key});

  @override
  State<TimerMapPage> createState() => _TimerMapPageState();
}

class _TimerMapPageState extends State<TimerMapPage> {
  static const _camera = CameraPosition(
    target: LatLng(37.4220, -122.0841),
    zoom: 15,
  );

  late final LiveTimerMarkersController _timers;

  /// Orange while an order is fresh, red once it has waited 15 minutes.
  static TimerMarkerStyle _waitingStyle(Duration waited) {
    if (waited >= const Duration(minutes: 15)) {
      return const TimerMarkerStyle(backgroundColor: Color(0xFFE53935));
    }
    return const TimerMarkerStyle();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timers = LiveTimerMarkersController(
      markers: [
        // An order that has been waiting for 4 minutes.
        TimerMarker.countUp(
          marker: const Marker(
            markerId: MarkerId('order-1'),
            position: LatLng(37.4250, -122.0870),
          ),
          since: now.subtract(const Duration(minutes: 4, seconds: 12)),
        ),
        // An order that turns red once it has waited 15 minutes.
        TimerMarker.countUp(
          marker: const Marker(
            markerId: MarkerId('order-2'),
            position: LatLng(37.4195, -122.0790),
          ),
          since: now.subtract(const Duration(minutes: 14, seconds: 50)),
          styleBuilder: _waitingStyle,
        ),
        // A pickup in 25 minutes, counting down.
        TimerMarker.countDown(
          marker: const Marker(
            markerId: MarkerId('pickup'),
            position: LatLng(37.4185, -122.0900),
          ),
          until: now.add(const Duration(minutes: 25)),
          style: const TimerMarkerStyle(backgroundColor: Color(0xFF1E88E5)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('live_timer_markers')),
      body: ValueListenableBuilder<Set<Marker>>(
        valueListenable: _timers,
        builder: (context, markers, _) => GoogleMap(
          initialCameraPosition: _camera,
          markers: markers,
        ),
      ),
    );
  }
}
