#!/usr/bin/env bash
# devdash integration tests — basic bash assertions, no external dependencies
set -euo pipefail

DEVDASH="$(cd "$(dirname "$0")/.." && pwd)/bin/devdash"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local code
  ( set +e; "$@" >/dev/null 2>&1; ) || true
  # Run again to capture real exit code without set -e interference
  set +e
  "$@" >/dev/null 2>&1
  code=$?
  set -e
  if [ "$code" -eq "$expected" ]; then
    pass "$desc"
  else
    fail "$desc (expected exit $expected, got $code)"
  fi
}

assert_contains() {
  local desc="$1" needle="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -qF "$needle"; then
    pass "$desc"
  else
    fail "$desc (expected output to contain '$needle')"
  fi
}

assert_not_empty() {
  local desc="$1"
  shift
  local output
  output=$("$@" 2>&1) || true
  if [ -n "$output" ]; then
    pass "$desc"
  else
    fail "$desc (output was empty)"
  fi
}

echo "=== devdash integration tests ==="
echo ""

# ── Version ──────────────────────────────────────────
echo "-- version --"
expected_version=$(jq -r '.version' "$(dirname "$0")/../package.json")
assert_contains "version matches package.json" "$expected_version" "$DEVDASH" version

# ── Help ─────────────────────────────────────────────
echo "-- help --"
assert_contains "help lists login"          "login"          "$DEVDASH" help
assert_contains "help lists init"           "init"           "$DEVDASH" help
assert_contains "help lists list"           "list"           "$DEVDASH" help
assert_contains "help lists ready"          "ready"          "$DEVDASH" help
assert_contains "help lists show"           "show"           "$DEVDASH" help
assert_contains "help lists create"         "create"         "$DEVDASH" help
assert_contains "help lists update"         "update"         "$DEVDASH" help
assert_contains "help lists close"          "close"          "$DEVDASH" help
assert_contains "help lists delete"         "delete"         "$DEVDASH" help
assert_contains "help lists dep"            "dep"            "$DEVDASH" help
assert_contains "help lists jobs"           "jobs"           "$DEVDASH" help
assert_contains "help lists stats"          "stats"          "$DEVDASH" help
assert_contains "help lists sync"           "sync"           "$DEVDASH" help
assert_contains "help lists prime"          "prime"          "$DEVDASH" help
assert_contains "help lists doctor"         "doctor"         "$DEVDASH" help
assert_contains "help lists alias-setup"    "alias-setup"    "$DEVDASH" help
assert_contains "help lists self-update"    "self-update"    "$DEVDASH" help
assert_contains "help lists project create" "project create" "$DEVDASH" help
assert_contains "help lists project list"   "project list"   "$DEVDASH" help
assert_contains "help lists project delete" "project delete" "$DEVDASH" help
assert_contains "help lists reconcile"      "reconcile"      "$DEVDASH" help

# ── Doctor ───────────────────────────────────────────
echo "-- doctor --"
assert_contains "doctor checks curl"     "curl"     "$DEVDASH" doctor
assert_contains "doctor checks jq"       "jq"       "$DEVDASH" doctor
assert_contains "doctor checks openssl"  "openssl"  "$DEVDASH" doctor
assert_contains "doctor checks python3"  "python3"  "$DEVDASH" doctor
assert_contains "doctor checks git"      "git"      "$DEVDASH" doctor
assert_contains "doctor checks token"    "token"    "$DEVDASH" doctor

# ── Error handling ───────────────────────────────────
echo "-- error handling --"
assert_exit "unknown command exits 1"     1 "$DEVDASH" xyzzy
assert_contains "unknown command message" "Unknown command" "$DEVDASH" xyzzy
assert_exit "show without args exits 1"   1 "$DEVDASH" show
assert_exit "create without title exits 1" 1 "$DEVDASH" create
assert_exit "delete without args exits 1" 1 "$DEVDASH" delete

# ── Unauthenticated ─────────────────────────────────
echo "-- unauthenticated access --"
_tmp_config_dir="$(mktemp -d)"
_tmp_token_file="${_tmp_config_dir}/token"
assert_contains "no-token shows login prompt" "devdash login" \
  env DD_CONFIG_DIR="$_tmp_config_dir" DD_TOKEN_FILE="$_tmp_token_file" "$DEVDASH" list
assert_exit "no-token exits 3 (config error)" 3 \
  env DD_CONFIG_DIR="$_tmp_config_dir" DD_TOKEN_FILE="$_tmp_token_file" "$DEVDASH" list
rm -rf "$_tmp_config_dir"

# ── Summary ──────────────────────────────────────────
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
