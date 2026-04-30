#!/usr/bin/env bash
set -e

# Exposes the local Rails server (port 3001) via ngrok.
# Run this in a separate terminal after starting bin/dev.
#
# Usage: script/ngrok_start_up.sh

PORT=${PORT:-3001}

echo "Starting ngrok tunnel on port $PORT..."
ngrok http "$PORT"
