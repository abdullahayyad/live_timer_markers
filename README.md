# live_timer_markers

[![CI](https://github.com/abdullahayyad/live_timer_markers/actions/workflows/ci.yml/badge.svg)](https://github.com/abdullahayyad/live_timer_markers/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/abdullahayyad/live_timer_markers/blob/main/LICENSE)

Live **count-up** and **countdown** timers on your
[`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter) markers:
"this order has been waiting **04:27**", "pickup in **24:10**".

<p align="center">
  <img src="https://raw.githubusercontent.com/abdullahayyad/live_timer_markers/main/doc/preview.svg" alt="Timer badges on a map: an orange 04:27, a red 15:02 and a blue 24:10" width="720">
  <br>
  <sub>Illustration of the badge styles.</sub>
</p>

Google Maps markers only accept images, so you can't put a ticking `Text`
widget on the map. This package draws each timer as a crisp badge, updates it
every second, and gives you a normal `Set<Marker>` to pass to `GoogleMap`.

## Features

- ⏱️ **Count up or down**: `TimerMarker.countUp(since: ...)` and
  `TimerMarker.countDown(until: ...)`.
- 🎨 **Styleable**: colors, font, padding, corner radius, outline, pointer and
  shadow.
- 🚦 **Styles that change with time**: turn a marker red after 15 minutes with
  `styleBuilder`.
- ⚡ **Efficient**: icons are cached and shared, and markers whose text didn't
  change are not sent to the map again.
- 🧩 **Keeps your marker**: id, position, `onTap`, info window and the rest
  stay as you set them; only the icon changes.
- 🧪 **Tested**, with no dependencies besides `google_maps_flutter`.

## Install

Until the package is on pub.dev, add it from GitHub:

```yaml
dependencies:
  live_timer_markers:
    git: https://github.com/abdullahayyad/live_timer_markers
```

It needs Flutter 3.22 or newer and `google_maps_flutter` 2.7 or newer. Set up
Google Maps itself as described in the
[`google_maps_flutter` guide](https://pub.dev/packages/google_maps_flutter#getting-started).

## Usage

Create a `LiveTimerMarkersController`, give it some `TimerMarker`s, and
rebuild the map when it changes:

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_timer_markers/live_timer_markers.dart';

class OrdersMap extends StatefulWidget {
  const OrdersMap({super.key});

  @override
  State<OrdersMap> createState() => _OrdersMapState();
}

class _OrdersMapState extends State<OrdersMap> {
  late final _timers = LiveTimerMarkersController(
    markers: [
      TimerMarker.countUp(
        marker: const Marker(
          markerId: MarkerId('order-42'),
          position: LatLng(37.4250, -122.0870),
        ),
        since: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ],
  );

  @override
  void dispose() {
    _timers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<Marker>>(
      valueListenable: _timers,
      builder: (context, markers, _) => GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.4220, -122.0841),
          zoom: 15,
        ),
        markers: markers,
      ),
    );
  }
}
```

Change the timers at any time:

```dart
_timers.addOrUpdate(TimerMarker.countDown(marker: pickup, until: pickupTime));
_timers.remove(const MarkerId('order-42'));
_timers.setMarkers(newTimers); // replace them all
_timers.stop(); // freeze the labels; start() resumes
```

Already have other markers? Merge them:

```dart
GoogleMap(markers: {...otherMarkers, ...timerMarkers}, ...)
```

## Styling

Set a default style on the controller, or a style per marker:

```dart
LiveTimerMarkersController(
  style: const TimerMarkerStyle(
    backgroundColor: Color(0xFF1E88E5),
    textColor: Colors.white,
    fontSize: 13,
    borderColor: Colors.white,
    borderWidth: 2,
    pointerSize: Size.zero, // no pointer under the badge
    shadowBlur: 0, // no shadow
  ),
);
```

### Styles that change with time

`styleBuilder` gets the current duration on every tick. For example, an order
that turns red once it has waited 15 minutes:

```dart
TimerMarker.countUp(
  marker: orderMarker,
  since: order.createdAt,
  styleBuilder: (waited) => waited >= const Duration(minutes: 15)
      ? const TimerMarkerStyle(backgroundColor: Color(0xFFE53935))
      : const TimerMarkerStyle(),
)
```

### Custom labels

Labels are `mm:ss`, or `hh:mm:ss` from one hour. Pass a formatter to change
them, on the controller or per marker:

```dart
TimerMarker.countDown(
  marker: pickupMarker,
  until: pickupTime,
  formatter: (left) => 'ETA ${formatTimerLabel(left)}',
)
```

## Good to know

- **Countdowns** round up, so the label reaches `00:00` exactly when the time
  is up, and then stays there.
- **Pixel ratio**: icons are drawn at the main screen's pixel ratio. If your
  app shows maps on other screens, pass
  `pixelRatio: MediaQuery.devicePixelRatioOf(context)`.
- **Performance**: each label is drawn once and cached (`maxCachedIcons`,
  256 by default), and markers with the same label share one bitmap. A few
  dozen live timers are no problem. For hundreds, use a longer `tickInterval`
  or a formatter that shows minutes only, so labels change less often.

## How it works

Every tick, the controller works out each marker's label, draws any label it
has not drawn before onto a canvas, and encodes it as a PNG. Each PNG becomes
a `BitmapDescriptor` that is reused for as long as the label stays the same.
Because unchanged markers keep the very same icon object, `GoogleMap` sees
that they did not change and leaves them alone.

## Example app

The [example](example) folder has a map with two orders counting up (one
turns red after 15 minutes) and a pickup counting down.

## Contributing

Issues and pull requests are welcome. Before opening a pull request, please
run:

```bash
flutter analyze
flutter test
```

## License

MIT. See [LICENSE](LICENSE).
