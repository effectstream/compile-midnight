#!/bin/bash
RELEASE_TAG=0.3.120
REPO=effectstream/binaries
source "$(dirname "$0")/versions.sh"

# Usage: ./upload.sh <macos-arm64|linux-amd64>
# Prerequisites:
#   brew install gh                                                                                                                      
#   gh auth login

ARCH=${1}

if [[ -z "${ARCH}" ]]; then
  echo "Error: ARCH argument required. Usage: ./upload.sh <macos-arm64|linux-amd64>"
  exit 1
fi

gh release upload ${RELEASE_TAG} \
  indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip \
  midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}.zip \
  midnight-node-${ARCH}-${NODE_VERSION}.zip \
  --repo ${REPO} \
  --clobber

echo "Done. ${ARCH} binaries uploaded to https://github.com/${REPO}/releases/tag/${RELEASE_TAG}"
