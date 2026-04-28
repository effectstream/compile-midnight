ARCH=linux-amd64
source "$(dirname "$0")/versions.sh"

# indexer-standalone
cd midnight-indexer-${INDEXER_VERSION}
cargo build --release --features standalone
cp "target/release/indexer-standalone" "target/release/indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
zip -j "../indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip" "target/release/indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
cd ..

# midnight-proof-server
cd midnight-ledger-ledger-${LEDGER_VERSION}
cargo build --release
cd proof-server
cargo build --release
cd ..
cp "target/release/midnight-proof-server" "target/release/midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}"
zip -j "../midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}.zip" "target/release/midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}"
cd ..

# midnight-node
cd midnight-node-node-${NODE_VERSION}
cargo build --release
cp "target/release/midnight-node" "target/release/midnight-node-${ARCH}-${NODE_VERSION}"
zip -j "../midnight-node-${ARCH}-${NODE_VERSION}.zip" "target/release/midnight-node-${ARCH}-${NODE_VERSION}"
zip -r "../midnight-node-${ARCH}-${NODE_VERSION}.zip" "res"
cd ..

echo "Done. Upload the zip files to https://github.com/effectstream/binaries/releases/edit/0.3.120"
