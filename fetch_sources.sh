#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/versions.sh"
cd "$SCRIPT_DIR"

clone_tag() {
  local repo=$1
  local ref=$2
  local commit=$3
  local dest=$4

  if [[ ! -d "$dest/.git" ]]; then
    git clone --branch "$ref" --depth 1 "$repo" "$dest"
  fi

  local actual_commit
  actual_commit=$(git -C "$dest" rev-parse HEAD)
  if [[ "$actual_commit" != "$commit" ]]; then
    echo "Wrong source commit for $dest: expected $commit, got $actual_commit" >&2
    exit 1
  fi
}

clone_commit() {
  local repo=$1
  local ref=$2
  local commit=$3
  local dest=$4

  if [[ ! -d "$dest/.git" ]]; then
    git init "$dest"
    git -C "$dest" remote add origin "$repo"
    git -C "$dest" fetch --depth 1 origin "$ref"
    git -C "$dest" checkout --detach FETCH_HEAD
  fi

  local actual_commit
  actual_commit=$(git -C "$dest" rev-parse HEAD)
  if [[ "$actual_commit" != "$commit" ]]; then
    echo "Wrong source commit for $dest: expected $commit, got $actual_commit" >&2
    exit 1
  fi
}

clone_tag https://github.com/midnightntwrk/midnight-indexer.git "$INDEXER_REF" "$INDEXER_COMMIT" "midnight-indexer-${INDEXER_VERSION}"
clone_tag https://github.com/midnightntwrk/midnight-ledger.git "$LEDGER_REF" "$LEDGER_COMMIT" "midnight-ledger-ledger-${LEDGER_VERSION}"
clone_commit https://github.com/midnightntwrk/midnight-ledger.git "$PROOF_SERVER_REF" "$PROOF_SERVER_COMMIT" "midnight-ledger-proof-server-${PROOF_SERVER_VERSION}"
clone_tag https://github.com/midnightntwrk/midnight-node.git "$NODE_REF" "$NODE_COMMIT" "midnight-node-node-${NODE_VERSION}"

echo "All source checkouts match the pinned commits."
