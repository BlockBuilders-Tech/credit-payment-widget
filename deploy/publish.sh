#!/usr/bin/env bash
#
# Build the widget and publish it to our nginx server.
#
#   ./deploy/publish.sh
#
# Uploads two copies:
#   /sdk/payment-widget.min.js             ← the live path merchants embed
#   /sdk/v<version>/payment-widget.min.js  ← pinned copy, for rollback
#
# The pinned copy is what makes a single live path safe: if a build turns out
# bad, restoring it is one command (see ROLLBACK at the bottom).

set -euo pipefail

# ── Configure once ──────────────────────────────────────────────────────
SSH_HOST="${SSH_HOST:-root@10.0.5.2}"
REMOTE_DIR="${REMOTE_DIR:-/usr/share/nginx/html/sdk}"
PUBLIC_URL="${PUBLIC_URL:-https://portaltest.qredit.tech/sdk/payment-widget.min.js}"
# ────────────────────────────────────────────────────────────────────────

cd "$(dirname "$0")/.."

VERSION="$(node -p "require('./package.json').version")"
FILE="dist/payment-widget.min.js"

echo "==> Building v${VERSION}"
npm run build

[ -f "$FILE" ] || { echo "build produced no $FILE"; exit 1; }

# Guard against publishing a bundle that won't parse — cheap, and a broken
# widget means every merchant's checkout stops working.
node --check "$FILE"
echo "==> Bundle parses OK ($(wc -c < "$FILE") bytes)"

echo "==> Publishing to ${SSH_HOST}:${REMOTE_DIR}"
ssh "$SSH_HOST" "mkdir -p '${REMOTE_DIR}/v${VERSION}'"

# Pinned copy first: if the live copy lands and the pinned one fails, there is
# nothing to roll back to.
scp "$FILE" "${SSH_HOST}:${REMOTE_DIR}/v${VERSION}/payment-widget.min.js"
scp "$FILE" "${SSH_HOST}:${REMOTE_DIR}/payment-widget.min.js"

echo "==> Published v${VERSION}"
echo
echo "Verify (expect 200, access-control-allow-origin: *):"
echo "  curl -sI ${PUBLIC_URL}"
echo
echo "ROLLBACK to a previous version:"
echo "  ssh ${SSH_HOST} 'cp ${REMOTE_DIR}/v<OLD>/payment-widget.min.js ${REMOTE_DIR}/payment-widget.min.js'"
