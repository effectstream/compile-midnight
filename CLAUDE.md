# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Build and release scripts for compiling Midnight network binaries (indexer, proof-server, node) for `macos-arm64` and `linux-amd64`, then uploading them to the `effectstream/binaries` GitHub release.

## Repository Layout

- `script_mac.sh` — builds all three binaries natively on macOS (macos-arm64)
- `script_linux.sh` — builds all three binaries for linux-amd64
- `upload.sh` — uploads the resulting zip files to a GitHub release via `gh`
- `versions.sh` — standalone version definitions (not yet sourced by the build scripts; versions are duplicated in each script)

Source directories (`midnight-indexer-*`, `midnight-ledger-*`, `midnight-node-*`) are gitignored and must be placed manually from upstream releases.

## Build Commands

All builds are Rust/Cargo. The scripts must be run from the repo root.

```bash
# macOS native build
./script_mac.sh

# Linux build (requires cross/Docker for cross-compilation, or run natively on Linux)
./script_linux.sh

# Upload to GitHub release (requires gh CLI, authenticated)
./upload.sh macos-arm64
./upload.sh linux-amd64
```

## Key Build Details

- **Indexer** is built with `cargo build --release --features standalone` (the `standalone` feature flag is required).
- **Proof server** requires building the ledger workspace root first (`cargo build --release` in `midnight-ledger-ledger-*/`), then building again inside `proof-server/`.
- **Node** zip includes both the binary and the `res/` directory (two separate `zip` calls: `-j` for binary, `-r` for `res/`).

## Version Management

`versions.sh` is the single source of truth for `INDEXER_VERSION`, `LEDGER_VERSION`, and `NODE_VERSION`. All scripts source it. When bumping versions, only edit `versions.sh`. The `upload.sh` script also has its own `RELEASE_TAG` and `REPO` variables.

## Upload Target

Binaries are uploaded to `github.com/effectstream/binaries` under release tag defined by `RELEASE_TAG` in `upload.sh` (currently `0.3.120`). The `--clobber` flag overwrites existing assets with the same name.
