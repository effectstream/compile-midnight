# midnight build scripts

Scripts to build and upload Midnight binaries for `macos-arm64` and `linux-amd64`.

## Prerequisites

- [Rust](https://rustup.rs/)
- [cross](https://github.com/cross-rs/cross) — for Linux cross-compilation: `cargo install cross`
- [Docker](https://www.docker.com/) — required by `cross`
- [GitHub CLI](https://cli.github.com/) — for uploading: `brew install gh && gh auth login`

## Setup

Before building, update the versions at the top of each script:

```bash
INDEXER_VERSION=<version>
LEDGER_VERSION=<version>
NODE_VERSION=<version>
```

Then place the corresponding source directories in this folder (not included in the repo):

- `midnight-indexer-<INDEXER_VERSION>/`
- `midnight-ledger-ledger-<LEDGER_VERSION>/`
- `midnight-node-node-<NODE_VERSION>/`

## Usage

### 1. Build macOS binaries (macos-arm64)

```bash
./script_mac.sh
```

### 2. Build Linux binaries (linux-amd64)

```bash
./script_linux.sh
```

### 3. Upload to GitHub release

```bash
./upload.sh macos-arm64
./upload.sh linux-amd64
```

## Output files

Each build produces 3 zip files in this directory:

| File | Contents |
|------|----------|
| `indexer-standalone-<arch>-v<INDEXER_VERSION>.zip` | `indexer-standalone` binary |
| `midnight-proof-server-<arch>-ledger-<LEDGER_VERSION>.zip` | `midnight-proof-server` binary |
| `midnight-node-<arch>-<NODE_VERSION>.zip` | `midnight-node` binary + `res/` folder |
