#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"

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

if [[ ! -f "$KEY_PROPERTIES" ]]; then
  cat <<'EOF'
Missing android/key.properties.

Create it from:
  android/key.properties.example

Then set storePassword, keyPassword, keyAlias, and storeFile.
EOF
  exit 1
fi

cd "$PROJECT_ROOT"

echo "Using Flutter: $FLUTTER_BIN"
echo "Building signed Play Store bundle..."
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build appbundle

echo
echo "Done. Upload this file to Google Play:"
echo "  $PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"
