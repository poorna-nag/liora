# Phase 7 (AR Companion) + Local Notifications

## Context

Liora is a feature-first Flutter AI-companion app. Phases 1–6 & 8 are shipped (chat, voice, vision, **Live Vision**, auto-memory, planner, lifestyle-coach modes) — all `flutter analyze` clean, 34 tests passing. This plan adds:

1. **Phase 7 — Augmented Reality:** a cross-platform AR feature (ARCore on Android, ARKit on iOS) where the user points the camera at a surface and taps to place a 3D model that stays anchored as they move, with scale/rotate/move gestures. This is the foundation for a future 3D AR companion (the placed model becomes the avatar later).
2. **Local notifications for the Planner** (the proactive-reminder half of Phases 6/9): schedule a real OS notification at a plan's due time. **Phase 10 cross-device backend sync is explicitly deferred** — reminders stay local for now.

**Confirmed decisions:** Plugin = `ar_flutter_plugin_engine` (most recent unified fork). Model = ship a sample/placeholder GLB at `assets/models/companion.glb` (with a public-URL fallback) + instructions to swap in a real model.

**Honest caveats (in the plan, not hidden):**
- AR **cannot be verified without a physical ARCore/ARKit device** (no AR on simulators/emulators).
- `ar_flutter_plugin_engine` is ~2024-era and pulls `permission_handler` + `geolocator`; a `dependency_overrides` entry and minor native build fixups are likely. The native build is the main risk on this modern toolchain (AGP 8.11 / Kotlin 2.2 / Java 17).
- Graceful-degradation (requirement 11) is therefore load-bearing: unsupported/older devices must see a friendly message, never a crash.

---

## Part A — AR feature (`features/ar/`)


Follows the exact feature-first pattern used by `vision`/`live_vision`. Reuses `PermissionService.requestCamera()` ([permission_service.dart](lib/core/services/permission_service.dart)).

### Dependencies (pubspec.yaml)
- Add `ar_flutter_plugin_engine` and `vector_math` (the plugin uses `Vector3`/`Matrix4`).
- Likely `dependency_overrides:` for `permission_handler` (keep project's `^12`) — verify on `pub get`; if the plugin hard-pins an older major, pin the highest compatible and note it.
- Add assets:
  ```yaml
  flutter:
    uses-material-design: true
    assets:
      - assets/models/
  ```
- Create `assets/models/companion.glb` (placeholder — see "Adding GLB assets" below).

### Android config
- [android/app/build.gradle.kts](android/app/build.gradle.kts): bump `minSdk` to `maxOf(24, flutter.minSdkVersion)` (ARCore/the plugin need 24+).
- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml): `CAMERA` already present. Inside `<application>` add `<meta-data android:name="com.google.ar.core" android:value="optional"/>`; above it add `<uses-feature android:name="android.hardware.camera.ar" android:required="false"/>` (`optional`/`required:false` so non-AR devices still install — supports requirement 11).

### iOS config
- [Info.plist](ios/Runner/Info.plist): `NSCameraUsageDescription` already present (reused for ARKit). Deployment target 15.0 is fine (ARKit needs ≥11).
- [Podfile](ios/Podfile): in the existing `post_install` add the permission preprocessor macros the plugin/`permission_handler` need (at minimum `PERMISSION_CAMERA=1`; include photos/location/sensors macros guarded as the plugin documents) so iOS builds link permissions correctly.

### Feature files (new, under `lib/features/ar/`)
- `utils/ar_constants.dart` — model asset path (`assets/models/companion.glb`), fallback GLB URL, default scale/min/max scale.
- `data/models/ar_placement.dart` — small value object (anchor id + node id + label) tracking placed objects.
- `data/services/ar_support_service.dart` — best-effort device-support probe + a single place that maps plugin errors → friendly messages (requirement 11).
- `presentation/bloc/ar_bloc.dart` (+ `ar_event.dart`, `ar_state.dart`, part-file style like `live_vision_bloc`) — thin: `ArStatus { initializing, ready, placing, unsupported, error }`, placed-object count, last error. Events: `ArStarted`, `ArObjectPlaced`, `ArCleared`, `ArUnsupportedDetected`, `ArErrorOccurred`. The plugin's session/object/anchor *managers* live in the screen; the bloc only mirrors status for the UI.
- `presentation/screen/ar_screen.dart` — **the `ARScreen` widget** (requirement 2). Requests camera permission first; on grant builds `ARView(onARViewCreated:, planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical)`. In `onARViewCreated`: `arSessionManager.onInitialize(showPlanes: true, handlePans: true, handleRotation: true, showFeaturePoints/worldOrigin: false)`, `arObjectManager.onInitialize()`. Wire `arSessionManager.onPlaneOrPointTap = _onTap` (hit-test → take first plane hit → `ARPlaneAnchor(transformation: hit.worldTransform)` → `arAnchorManager.addAnchor` → `ARNode(type: NodeType.localGLTF2, uri: companion.glb, scale: Vector3(0.2,0.2,0.2))` → `arObjectManager.addNode(node, planeAnchor: anchor)`); enable `onPanStart/Change/End` + `onRotationStart/Change/End` for move/rotate/scale (requirement 8); anchors keep nodes fixed in world space (requirement 9). `arSessionManager.onError` → emit `ArErrorOccurred`. Dispose all managers in `dispose()`.
- `presentation/widgets/ar_loading.dart` (spinner while AR initializes / model loads — requirement 10), `ar_unsupported.dart` (friendly "AR isn't supported on this device" — requirement 11), `ar_hint_banner.dart` ("Point at a surface, then tap to place").

### Wiring
- DI ([service_locator.dart](lib/core/di/service_locator.dart)): `registerLazySingleton<ArSupportService>`, `registerFactory<ArBloc>`.
- Route ([route_names.dart](lib/core/routing/route_names.dart) + [app_router.dart](lib/core/routing/app_router.dart)): `RouteNames.ar = '/ar'`; `GoRoute` providing `ArBloc`.
- Home tile ([home_repository_impl.dart](lib/features/home/data/repositories/home_repository_impl.dart)): `FeatureTile(title:'AR Companion', subtitle:'Place me in your space', icon: Icons.view_in_ar, route: RouteNames.ar)`.

### Adding GLB assets (instructions, delivered in code comments + this plan)
1. Put a `.glb` (single binary glТF) at `assets/models/companion.glb`.
2. Keep it small (<5 MB) and Y-up, real-world-meters scale; adjust `arScale` in `ar_constants.dart` if it appears too big/small.
3. Placeholder: ship a known-good small sample GLB (e.g. a simple shape) so the build is green immediately; `ar_constants.dart` also holds a public GLB URL fallback (`NodeType.webGLB`) used if the asset is missing.

---

## Part B — Local notifications for the Planner

Turns the existing in-app reminders into real scheduled OS notifications. Reuses the `planner` feature shipped earlier.

### Dependencies
- Add `flutter_local_notifications`, `timezone`, and `flutter_timezone` (to resolve the device's IANA zone for `zonedSchedule`).

### New service
- `lib/core/services/notification_service.dart` — `init()` (Android `@mipmap/ic_launcher` icon; iOS/macOS `DarwinInitializationSettings`), `requestPermission()` (Android 13 `POST_NOTIFICATIONS` + iOS prompt), `scheduleReminder(PlanItem)` via `zonedSchedule(...)` at `dueAt` using `AndroidScheduleMode.inexactAllowWhileIdle` (avoids the exact-alarm special permission), and `cancel(planId)`. Map `PlanItem.id` (uuid String) → stable `int` via hashing for the notification id.

### Init & platform config
- [app_initializer.dart](lib/core/init/app_initializer.dart): after Hive, `tz.initializeTimeZones()`, set local zone from `flutter_timezone`, then `NotificationService.init()`.
- Android [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml): add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` and the `flutter_local_notifications` `ScheduledNotificationReceiver` / boot receiver entries (for reminders surviving reboot). iOS: handled by the Darwin init + permission prompt (no Info.plist change needed).

### Hook into the planner
- Inject `NotificationService` into [planner_repository_impl.dart](lib/features/planner/data/repositories/planner_repository_impl.dart): `add()` schedules when `dueAt` is in the future; `delete()` cancels; `toggleDone()` cancels when marked done (re-schedules if un-done and still future).
- DI: register `NotificationService`; update `PlannerRepositoryImpl(sl(), sl(), sl())`.

---

## Verification
1. `flutter pub get` resolves (apply `dependency_overrides` if `ar_flutter_plugin_engine` conflicts on `permission_handler`); `flutter analyze` clean.
2. Unit tests (device-free): `NotificationService` id-hash stability; planner repo schedules/cancels via a mocked `NotificationService` (mocktail, mirroring existing bloc tests); `ar_support_service` error→message mapping. Run `flutter test` — keep the suite green.
3. **On-device AR smoke (needs a real ARCore/ARKit phone):** open AR Companion → camera permission → planes detected → tap a surface → model places and stays anchored while walking around → pan/rotate/pinch move/rotate/scale it → loading spinner shows during init/model load → on an AR-incapable device the unsupported message shows (no crash).
4. **Notifications:** add a plan due in ~1–2 min → background the app → OS notification fires; deleting/completing the plan cancels it.

## Critical files
- New: everything under `lib/features/ar/**`, `lib/core/services/notification_service.dart`, `assets/models/companion.glb`.
- Modified: `pubspec.yaml` (deps + assets), `android/app/build.gradle.kts` (minSdk 24), `android/app/src/main/AndroidManifest.xml` (AR meta-data + notification perms/receivers), `ios/Podfile` (permission macros), `lib/core/init/app_initializer.dart` (tz + notifications init), `lib/core/di/service_locator.dart`, `lib/core/routing/{route_names,app_router}.dart`, `lib/features/home/data/repositories/home_repository_impl.dart`, `lib/features/planner/data/repositories/planner_repository_impl.dart` (+ DI arg).

## What I need from the user
- A physical ARCore (Android) or ARKit (iPhone) device to validate AR — I can write/wire everything and get analyze/tests green, but can't run the AR session myself.
- (Optional now) a real `.glb` companion model to replace the placeholder; instructions are baked in so you can swap it anytime.
- Expect possible native build fixups on first device build (plugin is ~2024-era); deferred Phase 10 backend remains out of scope.
