# midnight-8 build scripts

Scripts to build and upload Midnight binaries for `macos-arm64` and `linux-amd64`.

## Versions

| Component | Version |
|-----------|---------|
| Indexer   | 4.0.0-rc.5 |
| Ledger    | 8.0.2 |
| Node      | 0.22.0-rc.10 |

## Prerequisites

- [Rust](https://rustup.rs/)
- [cross](https://github.com/cross-rs/cross) — for Linux cross-compilation: `cargo install cross`
- [Docker](https://www.docker.com/) — required by `cross`
- [GitHub CLI](https://cli.github.com/) — for uploading: `brew install gh && gh auth login`

## Source directories

The following source directories must be placed in this folder before building (not included in the repo):

- `midnight-indexer-4.0.0-rc.5/`
- `midnight-ledger-ledger-8.0.2/`
- `midnight-node-node-0.22.0-rc.10/`

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

Binaries are uploaded to the [`effectstream/binaries`](https://github.com/effectstream/binaries) repository, release tag `0.3.120`.

## Output files

Each build produces 3 zip files in this directory:

| File | Contents |
|------|----------|
| `indexer-standalone-<arch>-v4.0.0-rc.5.zip` | `indexer-standalone` binary |
| `midnight-proof-server-<arch>-ledger-8.0.2.zip` | `midnight-proof-server` binary |
| `midnight-node-<arch>-0.22.0-rc.10.zip` | `midnight-node` binary + `res/` folder |
