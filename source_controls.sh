#!/usr/bin/env bash

assert_pinned_source() {
  local source_dir=$1
  local expected_commit=$2
  local permitted_patch=${3:-}

  if [[ ! -d "$source_dir/.git" ]]; then
    echo "Missing source checkout: $source_dir. Run ./fetch_sources.sh first." >&2
    return 1
  fi

  local actual_commit
  if ! actual_commit=$(git -C "$source_dir" rev-parse HEAD); then
    echo "Cannot resolve source commit for $source_dir." >&2
    return 1
  fi
  if [[ "$actual_commit" != "$expected_commit" ]]; then
    echo "Wrong source commit for $source_dir: expected $expected_commit, got $actual_commit" >&2
    return 1
  fi

  if ! git -C "$source_dir" diff --cached --quiet --exit-code --; then
    echo "Staged source changes are forbidden in $source_dir." >&2
    return 1
  fi

  local untracked_files
  untracked_files=$(git -C "$source_dir" ls-files --others --exclude-standard)
  if [[ -n "$untracked_files" ]]; then
    echo "Untracked source files are forbidden in $source_dir:" >&2
    printf '%s\n' "$untracked_files" >&2
    return 1
  fi

  if git -C "$source_dir" diff --quiet --exit-code --; then
    return 0
  fi

  if [[ -z "$permitted_patch" ]]; then
    echo "Unstaged source changes are forbidden in $source_dir." >&2
    return 1
  fi
  if [[ ! -f "$permitted_patch" ]]; then
    echo "Missing permitted source patch: $permitted_patch" >&2
    return 1
  fi
  if [[ "$(git -C "$source_dir" diff --name-only --)" != "Cargo.lock" ]]; then
    echo "Only the recorded proof-server Cargo.lock patch is permitted in $source_dir." >&2
    return 1
  fi
  if ! git -C "$source_dir" diff -U1 -- Cargo.lock | cmp -s - "$permitted_patch"; then
    echo "Proof-server Cargo.lock differs from the recorded one-line normalization." >&2
    return 1
  fi
}

assert_recorded_patch_present() {
  local source_dir=$1
  local expected_commit=$2
  local permitted_patch=$3

  assert_pinned_source "$source_dir" "$expected_commit" "$permitted_patch"
  if git -C "$source_dir" diff --quiet --exit-code --; then
    echo "Required proof-server Cargo.lock normalization is absent in $source_dir." >&2
    return 1
  fi
}
