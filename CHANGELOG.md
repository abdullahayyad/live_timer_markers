## 0.1.0

* First release.
* `LiveTimerMarkersController` keeps timer markers ticking and exposes them
  as a `Set<Marker>`.
* `TimerMarker.countUp` and `TimerMarker.countDown`, with per-marker styles,
  `styleBuilder` and custom label formatters.
* `TimerMarkerStyle` for colors, font, padding, shape, outline, pointer and
  shadow.
* Icon caching: each label is drawn once and shared between markers.
