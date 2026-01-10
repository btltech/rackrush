# RackRush Flutter Build Guide

## Prerequisites

1. **Install Flutter SDK**
   ```bash
   # macOS with Homebrew
   brew install flutter
   
   # Or download from https://flutter.dev/docs/get-started/install
   ```

2. **Verify installation**
   ```bash
   flutter doctor
   ```

## Build for iOS

```bash
cd client

# Get dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d ios

# Build for App Store
flutter build ios --release

# Open in Xcode for archive
open ios/Runner.xcworkspace
```

## Build for Android

```bash
cd client

# Get dependencies
flutter pub get

# Run on Android Emulator
flutter run -d android

# Build APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

## Configuration

Update the server URL in `lib/services/socket_service.dart`:

```dart
static const String _prodUrl = 'https://rackrush-server-production.up.railway.app';
```

## Sound Effects

Add sound files to `assets/sounds/`:
- `tap.mp3` - Letter tile tap
- `submit.mp3` - Word submitted  
- `win.mp3` - Round/match won
- `lose.mp3` - Round/match lost
- `tick.mp3` - Timer warning
- `match_start.mp3` - Match begins

Free sound effects: https://freesound.org or https://mixkit.co/free-sound-effects/

## App Store Submission

1. Update `pubspec.yaml` version
2. Update iOS `Info.plist` with required permissions
3. Update Android `AndroidManifest.xml`
4. Generate app icons: `flutter pub run flutter_launcher_icons`
5. Archive and upload via Xcode (iOS) or Play Console (Android)
