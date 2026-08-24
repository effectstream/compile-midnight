#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ARCH=linux-amd64
source "$SCRIPT_DIR/versions.sh"
cd "$SCRIPT_DIR"

BUILD_LOCK_DIR="$SCRIPT_DIR/.build-${ARCH}.lock"
if ! mkdir "$BUILD_LOCK_DIR" 2>/dev/null; then
  echo "Another ${ARCH} packaging run owns $BUILD_LOCK_DIR; refusing concurrent writers." >&2
  exit 1
fi
cleanup_build_lock() {
  rmdir "$BUILD_LOCK_DIR"
}
trap cleanup_build_lock EXIT

INDEXER_EXECUTABLE="indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
INDEXER_ARCHIVE="indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip"
PROOF_EXECUTABLE="midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}"
PROOF_ARCHIVE="midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}.zip"
NODE_EXECUTABLE="midnight-node-${ARCH}-${NODE_VERSION}"
NODE_ARCHIVE="midnight-node-${ARCH}-${NODE_VERSION}.zip"

UPSTREAM_DIR="$SCRIPT_DIR/.upstream"
STAGE_DIR=$(mktemp -d "$SCRIPT_DIR/.stage-linux-amd64.XXXXXX")
INDEXER_CONTAINER="m2a-indexer-extract-$$"
PROOF_CONTAINER="m2a-proof-extract-$$"

cleanup() {
  docker rm -f "$INDEXER_CONTAINER" "$PROOF_CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$STAGE_DIR"
  cleanup_build_lock
}
trap cleanup EXIT

mkdir -p "$UPSTREAM_DIR"
rm -f "$INDEXER_ARCHIVE" "$PROOF_ARCHIVE" "$NODE_ARCHIVE" "SHA256SUMS-${ARCH}"

NODE_UPSTREAM_ARCHIVE="$UPSTREAM_DIR/midnight-node-${NODE_VERSION}-linux-amd64.tar.gz"
NODE_UPSTREAM_URL="https://github.com/midnightntwrk/midnight-node/releases/download/${NODE_REF}/midnight-node-${NODE_VERSION}-linux-amd64.tar.gz"
curl --fail --location --retry 3 --output "$NODE_UPSTREAM_ARCHIVE" "$NODE_UPSTREAM_URL"
echo "${NODE_LINUX_AMD64_RELEASE_SHA256}  ${NODE_UPSTREAM_ARCHIVE}" | shasum -a 256 --check

mkdir -p "$STAGE_DIR/node-upstream" "$STAGE_DIR/node-package"
tar -xzf "$NODE_UPSTREAM_ARCHIVE" -C "$STAGE_DIR/node-upstream"
NODE_SOURCE_BINARY=$(find "$STAGE_DIR/node-upstream" -type f -name midnight-node -print -quit)
NODE_SOURCE_RES=$(find "$STAGE_DIR/node-upstream" -type d -name res -print -quit)
if [[ -z "$NODE_SOURCE_BINARY" || -z "$NODE_SOURCE_RES" ]]; then
  echo "Official node release does not contain both midnight-node and res/." >&2
  exit 1
fi
install -m 0755 "$NODE_SOURCE_BINARY" "$STAGE_DIR/node-package/$NODE_EXECUTABLE"
cp -R "$NODE_SOURCE_RES" "$STAGE_DIR/node-package/res"
zip -j "$NODE_ARCHIVE" "$STAGE_DIR/node-package/$NODE_EXECUTABLE"
(
  cd "$STAGE_DIR/node-package"
  zip -r "$SCRIPT_DIR/$NODE_ARCHIVE" res
)

INDEXER_IMAGE="midnightntwrk/indexer-standalone@${INDEXER_LINUX_AMD64_IMAGE_DIGEST}"
docker pull --platform linux/amd64 "$INDEXER_IMAGE"
docker create --platform linux/amd64 --name "$INDEXER_CONTAINER" "$INDEXER_IMAGE" >/dev/null
docker cp "$INDEXER_CONTAINER:/usr/local/bin/indexer-standalone" "$STAGE_DIR/indexer-standalone"
install -m 0755 "$STAGE_DIR/indexer-standalone" "$STAGE_DIR/$INDEXER_EXECUTABLE"
zip -j "$INDEXER_ARCHIVE" "$STAGE_DIR/$INDEXER_EXECUTABLE"
docker rm "$INDEXER_CONTAINER" >/dev/null

PROOF_IMAGE="midnightntwrk/proof-server@${PROOF_SERVER_LINUX_AMD64_IMAGE_DIGEST}"
docker pull --platform linux/amd64 "$PROOF_IMAGE"
docker create --platform linux/amd64 --name "$PROOF_CONTAINER" "$PROOF_IMAGE" >/dev/null
PROOF_COMMAND=$(docker image inspect "$PROOF_IMAGE" --format '{{index .Config.Cmd 0}}')
PROOF_SOURCE_BINARY=${PROOF_COMMAND%% *}
docker cp "$PROOF_CONTAINER:$PROOF_SOURCE_BINARY" "$STAGE_DIR/midnight-proof-server"
install -m 0755 "$STAGE_DIR/midnight-proof-server" "$STAGE_DIR/$PROOF_EXECUTABLE"
zip -j "$PROOF_ARCHIVE" "$STAGE_DIR/$PROOF_EXECUTABLE"
docker rm "$PROOF_CONTAINER" >/dev/null

shasum -a 256 "$INDEXER_ARCHIVE" "$PROOF_ARCHIVE" "$NODE_ARCHIVE" > "SHA256SUMS-${ARCH}"
./validate_artifacts.sh "$ARCH"

echo "Packaged and validated official ${ARCH} artifacts for node ${NODE_VERSION}, indexer ${INDEXER_VERSION}, proof-server ${PROOF_SERVER_VERSION}."
