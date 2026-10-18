# live_timer_markers example

A map with three live timers: two orders that count up (one turns red after
15 minutes) and a pickup that counts down.

## Run it

This folder only holds the Dart code, so generate the platform folders first:

```bash
cd example
flutter create --platforms=android,ios .
```

Then add your Google Maps API key, as described in the
[google_maps_flutter setup guide](https://pub.dev/packages/google_maps_flutter#getting-started),
and run:

```bash
flutter run
```
