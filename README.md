# midnight build scripts

Scripts to build and upload the compatible Midnight node `2.0.0-rc.4`, indexer
`4.4.0-rc.1`, and plain proof-server `9.0.0-rc.5` stack for `macos-arm64` and
`linux-amd64`.

## Prerequisites

- [Rust](https://rustup.rs/)
- [Docker](https://www.docker.com/) — used to extract and validate official Linux images
- [GitHub CLI](https://cli.github.com/) — for uploading: `brew install gh && gh auth login`

## Setup

Fetch the exact source refs and verify their commits:

```bash
./fetch_sources.sh
```

The source directories and generated archives are intentionally gitignored. Exact
refs, commits, image digests, and the release target live in `versions.sh`.
Source verification fails closed on staged, unstaged, and untracked non-ignored
files. The proof-server checkout alone may contain the exact recorded Cargo.lock
normalization in `patches/proof-server-rc5-cargo-lock.patch`.

## Usage

### 1. Build macOS binaries (macos-arm64)

```bash
./script_mac.sh
```

The platform scripts use lock directories and refuse concurrent writers. Every
macOS run rebuilds all three archives from the verified pinned source; reuse of
pre-existing archives is intentionally unsupported.

### 2. Package official Linux binaries (linux-amd64)

```bash
./script_linux.sh
```

### 3. Upload to GitHub release

```bash
./upload.sh macos-arm64
./upload.sh linux-amd64
```

## Output files

Each run validates the extracted executables and produces three zip files plus a
platform checksum file in this directory:

| File | Contents |
|------|----------|
| `indexer-standalone-<arch>-v<INDEXER_VERSION>.zip` | `indexer-standalone` binary |
| `midnight-proof-server-<arch>-<PROOF_SERVER_VERSION>.zip` | `midnight-proof-server` binary |
| `midnight-node-<arch>-<NODE_VERSION>.zip` | `midnight-node` binary + `res/` folder |

The macOS binaries are source builds. Linux node comes from the upstream GitHub
release; Linux indexer and proof-server come from immutable official image
manifests. `ARTIFACTS.md` records the complete provenance and final release URLs.
