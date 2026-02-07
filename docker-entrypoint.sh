#!/usr/bin/env bash
set -euo pipefail

# Single bind-mounted directory from host
INJECT_DIR=${INJECT_DIR:-/inject_dir}

mkdir -p "$INJECT_DIR" \
  "$INJECT_DIR/ccproxy" \
  "$INJECT_DIR/claude" \
  "$INJECT_DIR/opencode" \
  "$INJECT_DIR/logs"

# Ensure parent dirs exist
mkdir -p /root
mkdir -p /tmp

# Replace expected paths with symlinks into INJECT_DIR
# These locations are used by ccproxy + CLI tools for OAuth/session storage.
rm -rf /root/.ccproxy /root/.claude /root/.opencode /tmp/ccproxy
ln -s "$INJECT_DIR/ccproxy" /root/.ccproxy
ln -s "$INJECT_DIR/claude" /root/.claude
ln -s "$INJECT_DIR/opencode" /root/.opencode
ln -s "$INJECT_DIR/logs" /tmp/ccproxy

exec "$@"
