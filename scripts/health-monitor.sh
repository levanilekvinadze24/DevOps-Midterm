#!/usr/bin/env bash
# Periodically curls the app's /health endpoint and append results to production/logs/health-check.log
# Usage: bash scripts/health-monitor.sh [&]
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URL="${HEALTHCHECK_URL:-http://127.0.0.1:${PROD_PORT:-3000}/health}"
INTERVAL_SEC="${HEALTH_INTERVAL_SEC:-30}"
LOG_DIR="$REPO/production/logs"
LOG_FILE="$LOG_DIR/health-check.log"

mkdir -p "$LOG_DIR"

echo "$(date -Iseconds 2>/dev/null || date) Monitoring $URL every ${INTERVAL_SEC}s -> $LOG_FILE (Ctrl+C to stop)"

while true; do
  TS="$(date -Iseconds 2>/dev/null || date)"
  if BODY="$(curl -sf --max-time 5 "$URL" 2>&1)"; then
    printf '%s STATUS=OK BODY=%s\n' "$TS" "$BODY" >>"$LOG_FILE"
  else
    printf '%s STATUS=FAIL BODY=%s\n' "$TS" "${BODY//$'\n'/ }" >>"$LOG_FILE"
  fi
  sleep "$INTERVAL_SEC"
done
