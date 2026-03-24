# ARCH=linux-amd64
ARCH=macos-arm64
INDEXER_VERSION=4.0.0
LEDGER_VERSION=8.0.3
NODE_VERSION=0.22.2

# download binaries from releases
# https://github.com/midnightntwrk/midnight-indexer/releases
# Unzip contents
cd midnight-indexer-${INDEXER_VERSION}
cargo build --release --features standalone
ls -l target/release/indexer-standalone
# Compress into zip file format: indexer-standalone-linux-amd64-v3.0.0-alpha.21.zip
# This file contains the binary only
cp "target/release/indexer-standalone" "target/release/indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
zip -j "../indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip" "target/release/indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
cd ..

# https://github.com/midnightntwrk/midnight-ledger/releases
cd midnight-ledger-ledger-${LEDGER_VERSION}
cargo build --release 
cd proof-server
cargo build --release
cd ..
ls -l target/release/midnight-proof-server 
# compress into zip file format: midnight-proof-server-linux-amd64-ledger-6.1.0-alpha.6.zip
# this file contains the binary only
cp "target/release/midnight-proof-server" "target/release/midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}"
zip -j "../midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}.zip" "target/release/midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}"
cd ..

# https://github.com/midnightntwrk/midnight-node/releases
cd midnight-node-node-${NODE_VERSION}
cargo build --release
ls -l res/
ls -l target/release/midnight-node
# compress into zip file with format: midnight-node-linux-amd64-0.18.0-rc.10.zip
# This file contains the binary and the res folder.
cp "target/release/midnight-node" "target/release/midnight-node-${ARCH}-${NODE_VERSION}"
zip -j "../midnight-node-${ARCH}-${NODE_VERSION}.zip" "target/release/midnight-node-${ARCH}-${NODE_VERSION}"
zip -r "../midnight-node-${ARCH}-${NODE_VERSION}.zip" "res"

cd ..
echo "Done. Upload the zip files to the https://github.com/effectstream/binaries/releases/edit/0.3.120 "
