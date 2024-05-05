#!/bin/bash
INSTALL_DIR="/opt/anything-llm"
export STORAGE_DIR="$INSTALL_DIR/storage"
cd "$INSTALL_DIR"/server && NODE_ENV=production node index.js &
cd "$INSTALL_DIR"/collector && NODE_ENV=production node index.js &
