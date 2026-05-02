#!/usr/bin/env bash
# Roll back to the previously active slot without rebuilding (swap recorded slots and restart).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVE_FILE="$REPO/deploy/state/active-slot"
PREV_FILE="$REPO/deploy/state/previous-slot"

ACTIVE="$(tr -d '\r\n' <"$ACTIVE_FILE")"
PREV="$(tr -d '\r\n' <"$PREV_FILE")"

if [[ "$ACTIVE" == "$PREV" ]]; then
  echo "ERROR: No rollback target recorded (previous slot equals active)." >&2
  exit 1
fi

TMP="$REPO/deploy/state/.slot-swap.$$"
echo "$ACTIVE" >"$TMP"
echo "$PREV" >"$ACTIVE_FILE"
cat "$TMP" >"$PREV_FILE"
rm -f "$TMP"

echo "Rollback: restored active slot to $(tr -d '\r\n' <"$ACTIVE_FILE")"
bash "$REPO/deploy/restart-live.sh"
