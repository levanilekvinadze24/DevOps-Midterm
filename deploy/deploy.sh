#!/usr/bin/env bash
# Blue-green style deploy: builds the inactive slot, warms it, flips traffic, restarts production.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PROD_PORT="${PROD_PORT:-3000}"

sync_slot() {
  local slot=$1
  local dest="$REPO/deploy/slots/$slot"
  rm -rf "$dest/src"
  mkdir -p "$dest/src/views"
  cp -f "$REPO/package.json" "$REPO/package-lock.json" "$dest/"
  cp -r "$REPO/src/." "$dest/src/"
  (cd "$dest" && npm ci --omit=dev)
}

warm_slot() {
  local dest=$1
  local slot=$2
  local warm_port=$3
  local version
  version="$(cd "$dest" && node -p "require('./package.json').version")"

  (
    cd "$dest"
    export PORT="$warm_port"
    export DEPLOY_SLOT="$slot"
    export APP_VERSION="${APP_VERSION_OVERRIDE:-$version}"
    node src/server.js >>"$REPO/production/logs/warm.log" 2>&1 &
    echo $! >"$REPO/production/.warm.pid"
  )
  sleep 1
  if ! curl -sf "http://127.0.0.1:${warm_port}/health" >/dev/null; then
    echo "ERROR: Warm-up health check failed for slot '$slot' on port ${warm_port}." >&2
    kill "$(tr -d '\r\n' <"$REPO/production/.warm.pid")" 2>/dev/null || true
    rm -f "$REPO/production/.warm.pid"
    exit 1
  fi
  WARM_PID="$(tr -d '\r\n' <"$REPO/production/.warm.pid")"
  kill "$WARM_PID" 2>/dev/null || true
  wait "$WARM_PID" 2>/dev/null || true
  rm -f "$REPO/production/.warm.pid"
}

ACTIVE="$(tr -d '\r\n' <"$REPO/deploy/state/active-slot")"
if [[ "$ACTIVE" == "blue" ]]; then
  INACTIVE="green"
else
  INACTIVE="blue"
fi

echo "Current active slot: $ACTIVE -> deploying to inactive slot: $INACTIVE"

sync_slot "$INACTIVE"
WARM_PORT=$((PROD_PORT + 9000))
warm_slot "$REPO/deploy/slots/$INACTIVE" "$INACTIVE" "$WARM_PORT"

echo "$ACTIVE" | tr -d '\r\n' >"$REPO/deploy/state/previous-slot"
echo "$INACTIVE" | tr -d '\r\n' >"$REPO/deploy/state/active-slot"

echo "Traffic switch (simulated): active slot is now $INACTIVE (previous live slot recorded as $ACTIVE)."
bash "$REPO/deploy/restart-live.sh"
