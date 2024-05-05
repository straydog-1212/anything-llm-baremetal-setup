#!/bin/bash
export INSTALL_DIR="/opt/anything-llm"
export STORAGE_DIR="$INSTALL_DIR/storage"
cd "$INSTALL_DIR"/server/utils/files && NODE_ENV=production node index.js &
cd "$INSTALL_DIR"/collector/utils/files/ && NODE_ENV=production node index.js &
