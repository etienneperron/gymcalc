#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"
KEYSTORE_DEFAULT_PATH="$PROJECT_ROOT/android/app/upload-keystore.jks"

ENV_FILE="$PROJECT_ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
KEYSTORE_PATH="${KEYSTORE_PATH:-$KEYSTORE_DEFAULT_PATH}"
KEY_ALIAS="${KEY_ALIAS:-upload}"
KEY_VALIDITY_DAYS="${KEY_VALIDITY_DAYS:-10000}"
KEYSTORE_CREATE_IF_MISSING="${KEYSTORE_CREATE_IF_MISSING:-0}"
ACCEPT_ANDROID_LICENSES="${ACCEPT_ANDROID_LICENSES:-1}"
ENSURE_ANDROID_CMDLINE_TOOLS="${ENSURE_ANDROID_CMDLINE_TOOLS:-1}"

if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  echo "Flutter CLI not found. Install Flutter or set FLUTTER_BIN to your flutter executable." >&2
  exit 1
fi

if [[ -d "$ANDROID_SDK_ROOT" ]]; then
  export ANDROID_SDK_ROOT
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
fi

ensure_android_cmdline_tools() {
  if [[ "$ENSURE_ANDROID_CMDLINE_TOOLS" != "1" ]]; then
    return 0
  fi

  if command -v sdkmanager >/dev/null 2>&1; then
    return 0
  fi

  echo "Android cmdline-tools (sdkmanager) not found in PATH."
  echo "Expected under: $ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
  echo "Install from Android Studio > SDK Manager > SDK Tools > Android SDK Command-line Tools (latest)."
  exit 1
}

prompt_secret_if_missing() {
  local var_name="$1"
  local prompt_label="$2"
  local value="${!var_name:-}"
  if [[ -n "$value" ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    echo "Missing required value: $var_name" >&2
    exit 1
  fi

  read -r -s -p "$prompt_label: " value
  echo
  if [[ -z "$value" ]]; then
    echo "$prompt_label cannot be empty." >&2
    exit 1
  fi
  printf -v "$var_name" '%s' "$value"
}

create_keystore_if_needed() {
  if [[ -f "$KEYSTORE_PATH" ]]; then
    return 0
  fi

  if [[ "$KEYSTORE_CREATE_IF_MISSING" != "1" ]]; then
    echo "Keystore not found at: $KEYSTORE_PATH"
    echo "Set KEYSTORE_CREATE_IF_MISSING=1 in .env to generate it automatically."
    exit 1
  fi

  if ! command -v keytool >/dev/null 2>&1; then
    echo "keytool command not found. Install a JDK first." >&2
    exit 1
  fi

  prompt_secret_if_missing KEYSTORE_PASSWORD "Enter keystore password"
  if [[ -z "${KEY_PASSWORD:-}" ]]; then
    KEY_PASSWORD="$KEYSTORE_PASSWORD"
  fi
  KEY_DNAME="${KEY_DNAME:-CN=GymCalc Upload,O=GymCalc,C=CA}"

  mkdir -p "$(dirname "$KEYSTORE_PATH")"
  echo "Creating upload keystore at $KEYSTORE_PATH"
  keytool -genkeypair -v \
    -keystore "$KEYSTORE_PATH" \
    -storetype JKS \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$KEY_VALIDITY_DAYS" \
    -alias "$KEY_ALIAS" \
    -dname "$KEY_DNAME" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD"
}

ensure_key_properties() {
  if [[ -f "$KEY_PROPERTIES" ]]; then
    return 0
  fi

  prompt_secret_if_missing KEYSTORE_PASSWORD "Enter keystore password"
  if [[ -z "${KEY_PASSWORD:-}" ]]; then
    KEY_PASSWORD="$KEYSTORE_PASSWORD"
  fi

  cat >"$KEY_PROPERTIES" <<EOF
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$(basename "$KEYSTORE_PATH")
EOF
}

accept_android_licenses_if_enabled() {
  if [[ "$ACCEPT_ANDROID_LICENSES" != "1" ]]; then
    return 0
  fi

  if ! command -v yes >/dev/null 2>&1; then
    echo "'yes' command not available; skipping automatic license acceptance."
    return 0
  fi

  echo "Accepting Android SDK licenses..."
  yes | "$FLUTTER_BIN" doctor --android-licenses >/dev/null || true
}

cd "$PROJECT_ROOT"

echo "Using Flutter: $FLUTTER_BIN"
echo "Using Android SDK: $ANDROID_SDK_ROOT"
ensure_android_cmdline_tools
create_keystore_if_needed
ensure_key_properties
accept_android_licenses_if_enabled
echo "Building signed Play Store bundle..."
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build appbundle

echo
echo "Done. Upload this file to Google Play:"
echo "  $PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"
