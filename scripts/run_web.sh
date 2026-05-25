#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

HOST="${1:-0.0.0.0}"
PORT="${2:-7357}"

cd "$PROJECT_ROOT"

echo "Using Flutter: $FLUTTER_BIN"
echo "Starting web server at http://$HOST:$PORT"
exec "$FLUTTER_BIN" run -d web-server --web-hostname "$HOST" --web-port "$PORT"
