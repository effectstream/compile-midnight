#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/versions.sh"
cd "$SCRIPT_DIR"

ARCH=${1:-}
if [[ "$ARCH" != "macos-arm64" && "$ARCH" != "linux-amd64" ]]; then
  echo "Usage: $0 <macos-arm64|linux-amd64>" >&2
  exit 1
fi

INDEXER_EXECUTABLE="indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
INDEXER_ARCHIVE="indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip"
PROOF_EXECUTABLE="midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}"
PROOF_ARCHIVE="midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}.zip"
NODE_EXECUTABLE="midnight-node-${ARCH}-${NODE_VERSION}"
NODE_ARCHIVE="midnight-node-${ARCH}-${NODE_VERSION}.zip"
VALIDATION_DIR=$(mktemp -d "$SCRIPT_DIR/.stage-validate-${ARCH}.XXXXXX")
PROOF_PROCESS_ID=""
PROOF_CONTAINER="m2a-proof-validate-$$"

cleanup() {
  if [[ -n "$PROOF_PROCESS_ID" ]]; then
    kill "$PROOF_PROCESS_ID" >/dev/null 2>&1 || true
    wait "$PROOF_PROCESS_ID" >/dev/null 2>&1 || true
  fi
  docker rm -f "$PROOF_CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$VALIDATION_DIR"
}
trap cleanup EXIT

for archive in "$INDEXER_ARCHIVE" "$PROOF_ARCHIVE" "$NODE_ARCHIVE"; do
  if [[ ! -f "$archive" ]]; then
    echo "Missing archive: $archive" >&2
    exit 1
  fi
done

mkdir -p "$VALIDATION_DIR/indexer" "$VALIDATION_DIR/proof" "$VALIDATION_DIR/node"
unzip -q "$INDEXER_ARCHIVE" -d "$VALIDATION_DIR/indexer"
unzip -q "$PROOF_ARCHIVE" -d "$VALIDATION_DIR/proof"
unzip -q "$NODE_ARCHIVE" -d "$VALIDATION_DIR/node"

INDEXER_BINARY="$VALIDATION_DIR/indexer/$INDEXER_EXECUTABLE"
PROOF_BINARY="$VALIDATION_DIR/proof/$PROOF_EXECUTABLE"
NODE_BINARY="$VALIDATION_DIR/node/$NODE_EXECUTABLE"

for binary in "$INDEXER_BINARY" "$PROOF_BINARY" "$NODE_BINARY"; do
  if [[ ! -x "$binary" ]]; then
    echo "Extracted file is missing or not executable: $binary" >&2
    exit 1
  fi
done

if [[ ! -d "$VALIDATION_DIR/node/res" ]]; then
  echo "Node archive is missing res/." >&2
  exit 1
fi

find_free_port() {
  local candidate
  for _ in $(seq 1 100); do
    candidate=$((10000 + RANDOM % 50000))
    if ! lsof -nP -iTCP:"$candidate" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PROOF_PORT=${PROOF_PORT:-$(find_free_port)}
VALIDATION_LOG="$SCRIPT_DIR/validation-${ARCH}.log"
: > "$VALIDATION_LOG"
echo "Proof validation port: $PROOF_PORT" | tee -a "$VALIDATION_LOG"

if [[ "$ARCH" == "macos-arm64" ]]; then
  file "$INDEXER_BINARY" "$PROOF_BINARY" "$NODE_BINARY" | tee -a "$VALIDATION_LOG"
  file "$INDEXER_BINARY" "$PROOF_BINARY" "$NODE_BINARY" | grep -q 'arm64'
  "$INDEXER_BINARY" --version | tee -a "$VALIDATION_LOG"
  "$NODE_BINARY" --version | tee -a "$VALIDATION_LOG"
  "$PROOF_BINARY" --no-fetch-params --port "$PROOF_PORT" >> "$VALIDATION_LOG" 2>&1 &
  PROOF_PROCESS_ID=$!
else
  file "$INDEXER_BINARY" "$PROOF_BINARY" "$NODE_BINARY" | tee -a "$VALIDATION_LOG"
  file "$INDEXER_BINARY" "$PROOF_BINARY" "$NODE_BINARY" | grep -q 'x86-64'
  INDEXER_IMAGE="midnightntwrk/indexer-standalone@${INDEXER_LINUX_AMD64_IMAGE_DIGEST}"
  PROOF_IMAGE="midnightntwrk/proof-server@${PROOF_SERVER_LINUX_AMD64_IMAGE_DIGEST}"
  NODE_IMAGE="midnightntwrk/midnight-node@${NODE_LINUX_AMD64_IMAGE_DIGEST}"
  docker run --rm --platform linux/amd64 \
    --entrypoint "/artifacts/$INDEXER_EXECUTABLE" \
    -v "$VALIDATION_DIR/indexer:/artifacts:ro" \
    "$INDEXER_IMAGE" --version | tee -a "$VALIDATION_LOG"
  docker run --rm --platform linux/amd64 \
    --entrypoint "/artifacts/$NODE_EXECUTABLE" \
    -v "$VALIDATION_DIR/node:/artifacts:ro" \
    "$NODE_IMAGE" --version | tee -a "$VALIDATION_LOG"
  docker run --rm --detach --platform linux/amd64 \
    --name "$PROOF_CONTAINER" \
    --entrypoint "/artifacts/$PROOF_EXECUTABLE" \
    -p "127.0.0.1:${PROOF_PORT}:${PROOF_PORT}" \
    -v "$VALIDATION_DIR/proof:/artifacts:ro" \
    "$PROOF_IMAGE" --no-fetch-params --port "$PROOF_PORT" >/dev/null
fi

VERSION_URL="http://127.0.0.1:${PROOF_PORT}/version"
for _ in $(seq 1 30); do
  if curl --fail --silent "$VERSION_URL" > "$VALIDATION_DIR/proof-version.json"; then
    break
  fi
  sleep 1
done

if [[ ! -s "$VALIDATION_DIR/proof-version.json" ]]; then
  echo "Proof server did not answer $VERSION_URL" >&2
  exit 1
fi

cat "$VALIDATION_DIR/proof-version.json" | tee -a "$VALIDATION_LOG"
grep -q "$PROOF_SERVER_VERSION" "$VALIDATION_DIR/proof-version.json"
grep -q "$INDEXER_VERSION" "$VALIDATION_LOG"
grep -q '2.0.0' "$VALIDATION_LOG"

shasum -a 256 "$INDEXER_ARCHIVE" "$PROOF_ARCHIVE" "$NODE_ARCHIVE" | tee -a "$VALIDATION_LOG"
echo "Validated archive contract and executed all ${ARCH} binaries." | tee -a "$VALIDATION_LOG"
