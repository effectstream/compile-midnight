# Midnight v9 artifact ledger

**Status**: PUBLISHED + REMOTE VERIFIED — 2026-08-23

**Release repository**: `effectstream/binaries`

**Release tag**: `0.3.120`

**Release page**: https://github.com/effectstream/binaries/releases/tag/0.3.120

## Compatibility lock

All six assets use one stack: node `2.0.0-rc.4`, indexer `4.4.0-rc.1`,
plain proof-server `9.0.0-rc.5`, and ledger source tag
`ledger-9.1.0.0-rc.3` where applicable.

| Component | Source repository | Exact tag/ref | Exact commit |
|---|---|---|---|
| Node | https://github.com/midnightntwrk/midnight-node | `node-2.0.0-rc.4` | `651e043b61ed445bf7a5066c60c87ea7bd606073` |
| Indexer | https://github.com/midnightntwrk/midnight-indexer | `v4.4.0-rc.1` | `668ed0258ac92bb25ed02cabe6075274d8fbaac8` |
| Ledger compatibility source | https://github.com/midnightntwrk/midnight-ledger | `ledger-9.1.0.0-rc.3` | `4823b5351b17cc49e30f19760dbd30a73cf95e22` |
| Plain proof-server | https://github.com/midnightntwrk/midnight-ledger | no upstream rc.5 source tag; exact version-bump ref `7a89f45d29792be7e09ca5eb246f1e69f0b2a179` | `7a89f45d29792be7e09ca5eb246f1e69f0b2a179` |

The ledger tag contains proof-server `9.0.0-rc.3`, not the required rc.5.
The rc.5 source commit has a stale self-version in `Cargo.lock`; the macOS build
applies only `patches/proof-server-rc5-cargo-lock.patch` (SHA-256
`cefb087dad02326e6ba144af3f8c3fa0aa1e30adc1647918b52c2822b7c5174f`)
to normalize that lock entry from rc.4 to rc.5 while retaining `--locked`.

The reproduction workflow requires clean staged, unstaged, and untracked
non-ignored state for indexer and node. Proof-server permits only that exact
unstaged Cargo.lock patch and requires clean staged/untracked state. Native
archive reuse is disabled: a reproduction rebuilds every macOS component from
those checked inputs. These control changes do not rebuild or alter the six
already published assets recorded below.

## Assets

| Component | Platform / arch | Source tag/ref and commit | Published input | Archive (bytes) | Extracted executable | SHA-256 | Final release URL | State |
|---|---|---|---|---|---|---|---|---|
| Indexer | macOS / arm64 | `v4.4.0-rc.1` @ `668ed0258ac92bb25ed02cabe6075274d8fbaac8` | Native source build | `indexer-standalone-macos-arm64-v4.4.0-rc.1.zip` (32641613) | `indexer-standalone-macos-arm64-v4.4.0-rc.1` | `39a3715f709a6c5b215802a1c7a290937cc19772cbb8f5a994330b3c4b987309` | https://github.com/effectstream/binaries/releases/download/0.3.120/indexer-standalone-macos-arm64-v4.4.0-rc.1.zip | published; remote digest + clean download verified |
| Plain proof-server | macOS / arm64 | rc.5 ref/commit `7a89f45d29792be7e09ca5eb246f1e69f0b2a179`; compatible ledger `ledger-9.1.0.0-rc.3` @ `4823b5351b17cc49e30f19760dbd30a73cf95e22` | Native source build plus recorded one-line lock normalization | `midnight-proof-server-macos-arm64-9.0.0-rc.5.zip` (7798041) | `midnight-proof-server-macos-arm64-9.0.0-rc.5` | `2149ba808892122cfab9ace2e382f4addecc2ecbe06b17dcd1bffece5a5be891` | https://github.com/effectstream/binaries/releases/download/0.3.120/midnight-proof-server-macos-arm64-9.0.0-rc.5.zip | published; remote digest + clean download verified |
| Node | macOS / arm64 | `node-2.0.0-rc.4` @ `651e043b61ed445bf7a5066c60c87ea7bd606073` | Native source build | `midnight-node-macos-arm64-2.0.0-rc.4.zip` (78815030) | `midnight-node-macos-arm64-2.0.0-rc.4` | `4ee77c1043dec716f7a1b133f0ebb8f23bbc3a704f348ae5708a6b58b330ed8c` | https://github.com/effectstream/binaries/releases/download/0.3.120/midnight-node-macos-arm64-2.0.0-rc.4.zip | published; remote digest + clean download verified |
| Indexer | Linux / amd64 | `v4.4.0-rc.1` @ `668ed0258ac92bb25ed02cabe6075274d8fbaac8` | Official `midnightntwrk/indexer-standalone:4.4.0-rc.1`, linux/amd64 digest `sha256:f3b71eaf3ba0985fc60ef5c007d3851b8f2834b4e83ab60ec7c6f8f4a8051dac`; OCI revision matches commit | `indexer-standalone-linux-amd64-v4.4.0-rc.1.zip` (35129707) | `indexer-standalone-linux-amd64-v4.4.0-rc.1` | `eae945b7381af69cd42c4d480f7be14117d6e24524816aa58db2b8bfd7aee3b4` | https://github.com/effectstream/binaries/releases/download/0.3.120/indexer-standalone-linux-amd64-v4.4.0-rc.1.zip | published; remote digest + clean download verified |
| Plain proof-server | Linux / amd64 | rc.5 ref/commit `7a89f45d29792be7e09ca5eb246f1e69f0b2a179`; compatible ledger `ledger-9.1.0.0-rc.3` @ `4823b5351b17cc49e30f19760dbd30a73cf95e22` | Official `midnightntwrk/proof-server:9.0.0-rc.5`, linux/amd64 digest `sha256:e912e04c48a7fdd385f05b313e4b52e0452cd8ccf6368816fa0c2effb5eb2361` | `midnight-proof-server-linux-amd64-9.0.0-rc.5.zip` (8435465) | `midnight-proof-server-linux-amd64-9.0.0-rc.5` | `a0db7b0613a86618d672c6aa6064519fb95aba6f9352cfbb351fed885d622124` | https://github.com/effectstream/binaries/releases/download/0.3.120/midnight-proof-server-linux-amd64-9.0.0-rc.5.zip | published; remote digest + clean download verified |
| Node | Linux / amd64 | `node-2.0.0-rc.4` @ `651e043b61ed445bf7a5066c60c87ea7bd606073` | Official GitHub asset `midnight-node-2.0.0-rc.4-linux-amd64.tar.gz`, upstream SHA-256 `f0397437ad4c1efa9e96c9ba1be17ac2168757471cbe96cef656576c74593d60` | `midnight-node-linux-amd64-2.0.0-rc.4.zip` (84751613) | `midnight-node-linux-amd64-2.0.0-rc.4` | `8f53e9dfb2c70ec2fb98fd6958466ef107685774ca4d93660bc63e7686948879` | https://github.com/effectstream/binaries/releases/download/0.3.120/midnight-node-linux-amd64-2.0.0-rc.4.zip | published; remote digest + clean download verified |

The official proof-server image has no OCI source/revision labels. Its immutable
digest is therefore the authoritative Linux input; the rc.5 source commit is
recorded separately and is the upstream commit that changes the package version
to `9.0.0-rc.5` immediately before the official image publication.

## Validation

- macOS host: macOS `15.7.3`, Apple Silicon `arm64`; node used repository-pinned
  Rust `1.95.0` and Homebrew clang `21.1.8` for wasm32; proof used Rust `1.95.0`.
- macOS archives were extracted and all three executables ran natively. `file`
  reported Mach-O arm64; versions were indexer `4.4.0-rc.1`, node `2.0.0`, and
  proof `/version` `9.0.0-rc.5`.
- Linux archives were extracted and all three executables ran as linux/amd64 in
  Docker using their immutable official component image digests for runtime
  dependencies. `file` reported ELF x86-64; the same versions were observed.
- Proof validation bound a random free host port above 10000 and all native
  processes/containers were torn down. Node archives also include `res/`.
- GitHub's release API reported matching SHA-256 and byte size for all six
  assets. Public unauthenticated range requests returned HTTP 206, and a fresh
  `gh release download` copy of every archive was byte-identical to local input.
