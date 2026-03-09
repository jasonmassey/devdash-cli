#!/usr/bin/env bash
# devdash integration tests — orchestrator
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

source "$DIR/helpers.sh"

echo "=== devdash integration tests ==="
echo ""

source "$DIR/test_offline.sh"
source "$DIR/test_api.sh"

test_summary
