#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")/.." && pwd)
source "$SCRIPT_DIR/source_controls.sh"

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/compile-midnight-remediation.XXXXXX")
cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

init_repo() {
  local repo_dir=$1
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init -q
  git -C "$repo_dir" config user.email remediation-test@example.invalid
  git -C "$repo_dir" config user.name remediation-test
  printf 'pinned source\n' > "$repo_dir/source.txt"
  git -C "$repo_dir" add source.txt
  git -C "$repo_dir" commit -q -m baseline
}

expect_rejected() {
  local description=$1
  shift
  if "$@" > "$TEST_DIR/rejection.log" 2>&1; then
    echo "Expected rejection: $description" >&2
    exit 1
  fi
  printf 'PASS reject: %s\n' "$description"
}

exercise_dirty_scopes() {
  local role=$1
  local repo_dir="$TEST_DIR/$role"
  local expected_commit

  init_repo "$repo_dir"
  expected_commit=$(git -C "$repo_dir" rev-parse HEAD)
  assert_pinned_source "$repo_dir" "$expected_commit"

  printf 'unstaged dirt\n' >> "$repo_dir/source.txt"
  expect_rejected "$role unstaged tracked source" assert_pinned_source "$repo_dir" "$expected_commit"
  git -C "$repo_dir" restore source.txt

  printf 'staged dirt\n' >> "$repo_dir/source.txt"
  git -C "$repo_dir" add source.txt
  expect_rejected "$role staged source" assert_pinned_source "$repo_dir" "$expected_commit"
  git -C "$repo_dir" restore --staged source.txt
  git -C "$repo_dir" restore source.txt

  printf 'untracked dirt\n' > "$repo_dir/untracked.txt"
  expect_rejected "$role untracked source" assert_pinned_source "$repo_dir" "$expected_commit"
  rm "$repo_dir/untracked.txt"
}

exercise_dirty_scopes indexer
exercise_dirty_scopes node
exercise_dirty_scopes proof

PROOF_FIXTURE="$TEST_DIR/proof-exact"
mkdir -p "$PROOF_FIXTURE"
git -C "$SCRIPT_DIR/midnight-ledger-proof-server-9.0.0-rc.5" archive HEAD Cargo.lock |
  tar -x -C "$PROOF_FIXTURE"
git -C "$PROOF_FIXTURE" init -q
git -C "$PROOF_FIXTURE" config user.email remediation-test@example.invalid
git -C "$PROOF_FIXTURE" config user.name remediation-test
git -C "$PROOF_FIXTURE" add Cargo.lock
git -C "$PROOF_FIXTURE" commit -q -m baseline
PROOF_FIXTURE_COMMIT=$(git -C "$PROOF_FIXTURE" rev-parse HEAD)
git -C "$PROOF_FIXTURE" apply "$SCRIPT_DIR/patches/proof-server-rc5-cargo-lock.patch"
assert_pinned_source \
  "$PROOF_FIXTURE" \
  "$PROOF_FIXTURE_COMMIT" \
  "$SCRIPT_DIR/patches/proof-server-rc5-cargo-lock.patch"
printf 'PASS allow: exact unstaged proof Cargo.lock patch\n'

printf 'extra dirt\n' > "$PROOF_FIXTURE/extra.txt"
expect_rejected \
  "proof exact patch plus untracked source" \
  assert_pinned_source \
  "$PROOF_FIXTURE" \
  "$PROOF_FIXTURE_COMMIT" \
  "$SCRIPT_DIR/patches/proof-server-rc5-cargo-lock.patch"
rm "$PROOF_FIXTURE/extra.txt"

printf '# extra tracked dirt\n' >> "$PROOF_FIXTURE/Cargo.lock"
expect_rejected \
  "proof Cargo.lock beyond recorded patch" \
  assert_pinned_source \
  "$PROOF_FIXTURE" \
  "$PROOF_FIXTURE_COMMIT" \
  "$SCRIPT_DIR/patches/proof-server-rc5-cargo-lock.patch"

REUSE_FIXTURE="$TEST_DIR/reuse"
mkdir -p "$REUSE_FIXTURE/patches"
cp "$SCRIPT_DIR/script_mac.sh" "$SCRIPT_DIR/source_controls.sh" "$SCRIPT_DIR/versions.sh" "$REUSE_FIXTURE/"
cp "$SCRIPT_DIR/patches/proof-server-rc5-cargo-lock.patch" "$REUSE_FIXTURE/patches/"
STALE_ARCHIVE="$REUSE_FIXTURE/indexer-standalone-macos-arm64-v4.4.0-rc.1.zip"
printf 'unapproved stale archive\n' > "$STALE_ARCHIVE"
STALE_DIGEST_BEFORE=$(shasum -a 256 "$STALE_ARCHIVE" | awk '{print $1}')
expect_rejected \
  "unapproved native archive reuse" \
  env REUSE_COMPLETED_COMPONENTS=1 bash "$REUSE_FIXTURE/script_mac.sh"
STALE_DIGEST_AFTER=$(shasum -a 256 "$STALE_ARCHIVE" | awk '{print $1}')
if [[ "$STALE_DIGEST_AFTER" != "$STALE_DIGEST_BEFORE" ]]; then
  echo "Rejected reuse mutated the stale archive fixture." >&2
  exit 1
fi
if [[ -e "$REUSE_FIXTURE/.build-macos-arm64.lock" ]]; then
  echo "Rejected reuse left a build lock." >&2
  exit 1
fi
printf 'PASS reject: stale archive remains untouched and no build starts\n'

grep -q 'assert_pinned_source' "$SCRIPT_DIR/fetch_sources.sh"
grep -q 'assert_pinned_source' "$SCRIPT_DIR/script_mac.sh"
if grep -q 'if \[\[ ! -f "\$INDEXER_ARCHIVE"' "$SCRIPT_DIR/script_mac.sh"; then
  echo "Indexer archive reuse branch remains in script_mac.sh." >&2
  exit 1
fi
if grep -q 'if \[\[ ! -f "\$PROOF_ARCHIVE"' "$SCRIPT_DIR/script_mac.sh"; then
  echo "Proof archive reuse branch remains in script_mac.sh." >&2
  exit 1
fi
printf 'PASS static: both entry points enforce shared controls and no archive reuse branch remains\n'
