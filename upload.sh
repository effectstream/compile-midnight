#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/versions.sh"
cd "$SCRIPT_DIR"

# Usage: ./upload.sh <macos-arm64|linux-amd64>
# Prerequisites:
#   brew install gh                                                                                                                      
#   gh auth login

ARCH=${1:-}

if [[ -z "${ARCH}" ]]; then
  echo "Error: ARCH argument required. Usage: ./upload.sh <macos-arm64|linux-amd64>"
  exit 1
fi

./validate_artifacts.sh "$ARCH"

gh release upload "$RELEASE_TAG" \
  "indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip" \
  "midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}.zip" \
  "midnight-node-${ARCH}-${NODE_VERSION}.zip" \
  --repo "$RELEASE_REPO" \
  --clobber

echo "Done. ${ARCH} binaries uploaded to https://github.com/${RELEASE_REPO}/releases/tag/${RELEASE_TAG}"
