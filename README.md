# GymCalc

GymCalc is a minimal Flutter Android app that calculates the weight to load on each side of a barbell for 1 to 20 reps.

## What the app does

- Lets you enter a max weight in pounds.
- Lets you choose how many rep rows to show, from 1 to 20.
- Lets you edit the percentage of max for each rep.
- Rounds the load per side to the nearest 2.5 lb.
- Shows the plate breakdown per side using 45 lb, 25 lb, 10 lb, 5 lb, and 2.5 lb plates.
- Saves max weight, bar weight, rep count, and percentages between launches.

The app starts with a 45 lb bar by default, but the bar weight is editable.

## Finish the Linux setup

### 1. Add Flutter to your PATH

Add this line to your `~/.zshrc`:

```bash
export PATH="<path-to-your-flutter-sdk>/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.zshrc
```

Verify it:

```bash
flutter --version
dart --version
```

### 2. Install Android Studio

On Ubuntu, the simplest path is:

```bash
sudo snap install android-studio --classic
```

Then launch Android Studio and let the first-run wizard install:

- Android SDK
- Android SDK Platform
- Android SDK Command-line Tools
- Android Emulator

### 3. Point Flutter at the Android SDK if needed

Android Studio usually installs the SDK in:

```bash
$HOME/Android/Sdk
```

If `flutter doctor` still cannot find it, run:

```bash
flutter config --android-sdk "$HOME/Android/Sdk"
```

### 4. Accept Android licenses

```bash
flutter doctor --android-licenses
```

### 5. Re-run the environment check

```bash
flutter doctor
```

You want the Android toolchain line to pass before trying to run the app on an emulator or phone.

## Run the app

From this project folder:

```bash
flutter pub get
flutter run
```

If you want to target a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Quickstart For New Developers

1. Install Flutter and add it to your PATH.
2. Clone the repository and open the project root.
3. Run `flutter pub get`.
4. Validate with `flutter test` and `flutter analyze`.
5. Start lightweight UI development with `./scripts/run_web.sh`.

## Scripts

The project includes helper scripts in [scripts/run_web.sh](scripts/run_web.sh), [scripts/deploy_playstore.sh](scripts/deploy_playstore.sh), and [scripts/build_apk.sh](scripts/build_apk.sh).

By default, scripts use `flutter` from your `PATH`. You can override with:

```bash
FLUTTER_BIN=/absolute/path/to/flutter ./scripts/run_web.sh
```

## Development notes

- Main app code lives in `lib/main.dart`.
- Widget and logic checks live in `test/widget_test.dart`.
- The calculator rounds per-side load to the nearest 2.5 lb before building the plate list.

## Validation

The current project passes:

```bash
flutter test
```

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).

## Play Store Release Setup

Privacy policy: see [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

To generate a signed Android App Bundle for Play Store upload:

1. Create a release keystore with Android Studio or `keytool`.
2. Copy [android/key.properties.example](android/key.properties.example) to `android/key.properties`.
3. Update the values in `android/key.properties` to match your keystore.
4. Keep the keystore file in `android/app/` at the path you set in `storeFile`.
5. Build the release bundle with:

```bash
flutter build appbundle
```

The generated bundle will be under `build/app/outputs/bundle/release/`.
