# Liora — AI Companion Assistant

A production-oriented Flutter AI companion: chat, voice, vision, multilingual
conversation and translation, backed by Gemini (via **Firebase AI Logic**, so no
API key ships in the app).

## Architecture

Feature-first **Clean Architecture** with **BLoC** and **GetIt** DI.

```
lib/
  core/            # constants, theme, routing, DI, services, session, storage
  features/<name>/
    data/
      models/          # entities
      repositories/    # abstract contract + *_impl
    presentation/
      bloc/            # bloc + event + state
      screen/          # widgets
```

Key seams:
- `SessionManager` / `UserContext` — single identity source; storage scopes by
  `userId`, so guest ↔ authenticated transitions need no repository changes.
- `GeminiService` / `AuthService` — Firebase-backed services guarded by an
  `isAvailable` flag. With no Firebase config the app still **runs fully
  offline**: guest mode works, AI features report they're offline.
- `AppRouter` — `go_router` with an auth-gating `redirect` + `refreshListenable`.

## Authentication

Splash → (if signed out) Login → Home. Supported methods:
- **Email/password** (sign in, sign up, password reset) via Firebase Auth.
- **Google** via `google_sign_in` 7.x + a Firebase credential.
- **Guest** — a local identity (`guest_<uuid>`); works with no backend. Guests
  can later open Login from Home/Settings to upgrade.

Flow: `AuthBloc` drives the screens; on success `AuthRepository` flips its
`AuthStatus`, the router redirect observes it and navigates. Sign out lives in
**Settings → Account**.

## Setup

1. Install deps:
   ```bash
   flutter pub get
   ```

2. **Firebase** (required for accounts + AI; the app runs without it in guest/
   offline mode):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure        # generates firebase_options.dart + native config
   ```
   In the Firebase console enable: **Authentication** (Email/Password + Google),
   **Firestore**, **Storage**, and **Firebase AI Logic** (Gemini).

   > `AppInitializer._initFirebase()` calls `Firebase.initializeApp()` and
   > degrades gracefully if config is absent. If you generate
   > `firebase_options.dart`, pass `options: DefaultFirebaseOptions.currentPlatform`.

3. **Google Sign-In on Android** needs the Web client ID as the server client id
   so Firebase accepts the returned token:
   ```bash
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
   ```
   (iOS uses the reversed client ID from `GoogleService-Info.plist`.)

4. Run:
   ```bash
   flutter run
   ```

## Permissions

`INTERNET`, `RECORD_AUDIO` (voice) and `CAMERA` (vision) are declared in the
Android manifest; iOS usage strings live in `ios/Runner/Info.plist`. Runtime
prompts are handled by `PermissionService`.

## Tests

```bash
flutter test
```
