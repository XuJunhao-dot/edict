#!/usr/bin/env bash
set -euo pipefail

# Ensure localhost requests bypass any system proxy (mihomo/clash/etc.)
export NO_PROXY="localhost,127.0.0.1"
export no_proxy="localhost,127.0.0.1"

# Also clear proxy vars for this process (so python/urllib won't proxy local calls)
unset ALL_PROXY all_proxy HTTP_PROXY http_proxy HTTPS_PROXY https_proxy

cd "$(dirname "$0")/.."
exec python3 dashboard/server.py --port 7898 --host 127.0.0.1
