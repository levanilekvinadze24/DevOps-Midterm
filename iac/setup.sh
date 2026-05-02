#!/usr/bin/env bash
# Single-command environment preparation (IaC-style automation).
# Usage: bash iac/setup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p \
  deploy/slots/blue \
  deploy/slots/green \
  production/logs \
  docs/screenshots

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Node.js is not installed or not on PATH." >&2
  echo "Install Node.js 18+ from https://nodejs.org/ (LTS recommended)." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm is not available." >&2
  exit 1
fi

echo "Node $(node -v), npm $(npm -v)"
echo "Installing application dependencies (repository root)..."
npm ci

echo "Verifying tests and lint..."
npm test
npm run lint

copy_to_slot() {
  local slot=$1
  local dest="$ROOT/deploy/slots/$slot"
  mkdir -p "$dest"
  rm -rf "$dest/src"
  cp -f package.json package-lock.json "$dest/"
  cp -r src "$dest/"
  (cd "$dest" && npm ci --omit=dev)
}

echo "Provisioning local production slots (blue/green mirrors)..."
copy_to_slot blue
copy_to_slot green

echo "IaC setup complete."
echo "Start local production from the active slot: bash deploy/restart-live.sh"
