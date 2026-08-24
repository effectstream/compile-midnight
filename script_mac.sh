#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ARCH=macos-arm64
source "$SCRIPT_DIR/versions.sh"
source "$SCRIPT_DIR/source_controls.sh"
cd "$SCRIPT_DIR"

if [[ "${REUSE_COMPLETED_COMPONENTS:-0}" != 0 ]]; then
  echo "REUSE_COMPLETED_COMPONENTS is unsupported: native archives must be rebuilt from the verified pinned sources." >&2
  exit 1
fi

BUILD_LOCK_DIR="$SCRIPT_DIR/.build-${ARCH}.lock"
if ! mkdir "$BUILD_LOCK_DIR" 2>/dev/null; then
  echo "Another ${ARCH} build owns $BUILD_LOCK_DIR; refusing concurrent writers." >&2
  exit 1
fi
cleanup_build_lock() {
  rmdir "$BUILD_LOCK_DIR"
}
trap cleanup_build_lock EXIT

INDEXER_DIR="midnight-indexer-${INDEXER_VERSION}"
PROOF_SERVER_DIR="midnight-ledger-proof-server-${PROOF_SERVER_VERSION}"
NODE_DIR="midnight-node-node-${NODE_VERSION}"

PROOF_LOCK_PATCH="$SCRIPT_DIR/patches/proof-server-rc5-cargo-lock.patch"
assert_pinned_source "$INDEXER_DIR" "$INDEXER_COMMIT"
assert_pinned_source "$PROOF_SERVER_DIR" "$PROOF_SERVER_COMMIT" "$PROOF_LOCK_PATCH"
assert_pinned_source "$NODE_DIR" "$NODE_COMMIT"

if grep -q 'version = "9.0.0-rc.4"' "$PROOF_SERVER_DIR/Cargo.lock"; then
  git -C "$PROOF_SERVER_DIR" apply "$PROOF_LOCK_PATCH"
fi
assert_recorded_patch_present "$PROOF_SERVER_DIR" "$PROOF_SERVER_COMMIT" "$PROOF_LOCK_PATCH"

INDEXER_EXECUTABLE="indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
INDEXER_ARCHIVE="indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip"
PROOF_EXECUTABLE="midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}"
PROOF_ARCHIVE="midnight-proof-server-${ARCH}-${PROOF_SERVER_VERSION}.zip"
NODE_EXECUTABLE="midnight-node-${ARCH}-${NODE_VERSION}"
NODE_ARCHIVE="midnight-node-${ARCH}-${NODE_VERSION}.zip"

rm -f "$INDEXER_ARCHIVE" "$PROOF_ARCHIVE" "$NODE_ARCHIVE" "SHA256SUMS-${ARCH}"

(
  cd "$INDEXER_DIR"
  cargo build --locked --release --features standalone --package indexer-standalone
  install -m 0755 target/release/indexer-standalone "target/release/${INDEXER_EXECUTABLE}"
  zip -j "../${INDEXER_ARCHIVE}" "target/release/${INDEXER_EXECUTABLE}"
)

(
  cd "$PROOF_SERVER_DIR"
  cargo +1.95.0 build --locked --release --package midnight-proof-server
  install -m 0755 target/release/midnight-proof-server "target/release/${PROOF_EXECUTABLE}"
  zip -j "../${PROOF_ARCHIVE}" "target/release/${PROOF_EXECUTABLE}"
)

(
  cd "$NODE_DIR"
  WASM_CLANG=${WASM_CLANG:-$(brew --prefix llvm)/bin/clang}
  if ! "$WASM_CLANG" --print-targets | grep -q wasm32; then
    echo "Clang does not provide the wasm32 target: $WASM_CLANG" >&2
    exit 1
  fi
  env \
    CC_wasm32v1_none="$WASM_CLANG" \
    CC_wasm32_unknown_unknown="$WASM_CLANG" \
    CFLAGS_wasm32v1_none=-Wno-error=implicit-function-declaration \
    CFLAGS_wasm32_unknown_unknown=-Wno-error=implicit-function-declaration \
    cargo build --locked --release --package midnight-node
  install -m 0755 target/release/midnight-node "target/release/${NODE_EXECUTABLE}"
  zip -j "../${NODE_ARCHIVE}" "target/release/${NODE_EXECUTABLE}"
  zip -r "../${NODE_ARCHIVE}" res
)

shasum -a 256 "$INDEXER_ARCHIVE" "$PROOF_ARCHIVE" "$NODE_ARCHIVE" > "SHA256SUMS-${ARCH}"
./validate_artifacts.sh "$ARCH"

echo "Built and validated ${ARCH} artifacts for node ${NODE_VERSION}, indexer ${INDEXER_VERSION}, proof-server ${PROOF_SERVER_VERSION}."
