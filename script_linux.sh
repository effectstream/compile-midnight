ARCH=linux-amd64
TARGET=x86_64-unknown-linux-gnu
INDEXER_VERSION=4.0.0
LEDGER_VERSION=8.0.3
NODE_VERSION=0.22.2

# TODO this is not working yet
# Requires: cargo install cross + Docker running for cross compilation

# indexer-standalone
cd midnight-indexer-${INDEXER_VERSION}
cross build --release --features standalone --target ${TARGET}
cp "target/${TARGET}/release/indexer-standalone" "target/${TARGET}/release/indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
zip -j "../indexer-standalone-${ARCH}-v${INDEXER_VERSION}.zip" "target/${TARGET}/release/indexer-standalone-${ARCH}-v${INDEXER_VERSION}"
cd ..

# midnight-proof-server
cd midnight-ledger-ledger-${LEDGER_VERSION}
cross build --release --target ${TARGET}
cd proof-server
cross build --release --target ${TARGET}
cd ..
cp "target/${TARGET}/release/midnight-proof-server" "target/${TARGET}/release/midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}"
zip -j "../midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}.zip" "target/${TARGET}/release/midnight-proof-server-${ARCH}-ledger-${LEDGER_VERSION}"
cd ..

# midnight-node
cd midnight-node-node-${NODE_VERSION}
cross build --release --target ${TARGET}
cp "target/${TARGET}/release/midnight-node" "target/${TARGET}/release/midnight-node-${ARCH}-${NODE_VERSION}"
zip -j "../midnight-node-${ARCH}-${NODE_VERSION}.zip" "target/${TARGET}/release/midnight-node-${ARCH}-${NODE_VERSION}"
zip -r "../midnight-node-${ARCH}-${NODE_VERSION}.zip" "res"
cd ..

echo "Done. Upload the zip files to https://github.com/effectstream/binaries/releases/edit/0.3.120"
