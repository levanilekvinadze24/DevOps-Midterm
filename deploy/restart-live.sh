#!/usr/bin/env bash
# Starts (or restarts) the production server from the currently active blue/green slot.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PROD_PORT="${PROD_PORT:-3000}"
PID_FILE="$REPO/production/app.pid"
LOG_FILE="$REPO/production/logs/server.log"

mkdir -p "$REPO/production/logs"

if [[ -f "$PID_FILE" ]]; then
  PID="$(tr -d '\r\n' < "$PID_FILE")"
  kill "$PID" 2>/dev/null || true
  rm -f "$PID_FILE"
fi

ACTIVE="$(tr -d '\r\n' < "$REPO/deploy/state/active-slot")"
SLOT_DIR="$REPO/deploy/slots/$ACTIVE"
if [[ ! -f "$SLOT_DIR/package.json" ]]; then
  echo "ERROR: Slot '$ACTIVE' is empty. Run: bash iac/setup.sh then bash deploy/deploy.sh" >&2
  exit 1
fi

APP_VERSION="$(cd "$SLOT_DIR" && node -p "require('./package.json').version")"

(
  cd "$SLOT_DIR"
  export NODE_ENV=production
  export PORT="$PROD_PORT"
  export DEPLOY_SLOT="$ACTIVE"
  export APP_VERSION
  nohup node src/server.js >>"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
)

sleep 1
if ! curl -sf "http://127.0.0.1:${PROD_PORT}/health" >/dev/null; then
  echo "ERROR: Health check failed after restart on port ${PROD_PORT}." >&2
  exit 1
fi

echo "Production listening on ${PROD_PORT} (slot=${ACTIVE}, version=${APP_VERSION})."
