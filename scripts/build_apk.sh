#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_PROPERTIES="$PROJECT_ROOT/android/key.properties"

ENV_FILE="$PROJECT_ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  echo "Flutter CLI not found. Install Flutter or set FLUTTER_BIN to your flutter executable." >&2
  exit 1
fi

cd "$PROJECT_ROOT"

echo "Using Flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" pub get

if [[ -f "$KEY_PROPERTIES" ]]; then
  echo "Building release APK (signed)..."
  "$FLUTTER_BIN" build apk --release
  echo
  echo "Done. Install this APK on your phone:"
  echo "  $PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
else
  echo "android/key.properties not found; building debug APK for sideload testing."
  "$FLUTTER_BIN" build apk --debug
  echo
  echo "Done. Install this APK on your phone:"
  echo "  $PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"
fi
