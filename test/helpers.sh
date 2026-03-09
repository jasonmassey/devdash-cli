#!/usr/bin/env bash
# Test helpers — assertions and API test setup/teardown

DEVDASH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/devdash"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local code=$?
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

assert_not_contains() {
  local desc="$1" needle="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -qF "$needle"; then
    fail "$desc (output should NOT contain '$needle')"
  else
    pass "$desc"
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

assert_api_called() {
  local desc="$1" method="$2" endpoint="$3"
  if grep -qF "${method} ${endpoint}" "$MOCK_CURL_LOG" 2>/dev/null; then
    pass "$desc"
  else
    fail "$desc (expected ${method} ${endpoint} in curl log)"
  fi
}

assert_api_body() {
  local desc="$1" method="$2" endpoint="$3" expected="$4"
  local line
  line=$(grep -F "${method} ${endpoint}" "$MOCK_CURL_LOG" 2>/dev/null | head -1)
  if [ -z "$line" ]; then
    fail "$desc (no ${method} ${endpoint} call found)"
    return
  fi
  # Body is everything after "METHOD /endpoint "
  local body="${line#"${method} ${endpoint} "}"
  if echo "$body" | grep -qF "$expected"; then
    pass "$desc"
  else
    fail "$desc (body missing '$expected', got: $body)"
  fi
}

# Setup mock API environment
# Sets: MOCK_CURL_FIXTURE_DIR, MOCK_CURL_LOG, DD_CONFIG_DIR, DD_TOKEN_FILE, _MOCK_TMPDIR, _MOCK_WORKDIR, _ORIG_PATH
setup_api_test() {
  _MOCK_TMPDIR=$(mktemp -d)
  _MOCK_WORKDIR=$(mktemp -d)

  # Config directory with a fake token
  export DD_CONFIG_DIR="${_MOCK_TMPDIR}/config"
  mkdir -p "$DD_CONFIG_DIR"
  export DD_TOKEN_FILE="${DD_CONFIG_DIR}/token"
  echo "mock-token-for-testing" > "$DD_TOKEN_FILE"

  # Write .devdash project file in the working directory
  echo '{"api_url":"http://localhost:9999","project_id":"95ca3de0-7e4f-4f9e-9b17-36f5609cfa11"}' > "${_MOCK_WORKDIR}/.devdash"

  # Mock curl setup
  export MOCK_CURL_FIXTURE_DIR="${TEST_DIR}/fixtures"
  export MOCK_CURL_LOG="${_MOCK_TMPDIR}/curl.log"
  : > "$MOCK_CURL_LOG"

  # Prepend mock curl to PATH
  _ORIG_PATH="$PATH"
  export PATH="${TEST_DIR}/mock:${PATH}"
}

teardown_api_test() {
  export PATH="$_ORIG_PATH"
  rm -rf "$_MOCK_TMPDIR" "$_MOCK_WORKDIR"
  unset MOCK_CURL_FIXTURE_DIR MOCK_CURL_LOG DD_CONFIG_DIR DD_TOKEN_FILE _MOCK_TMPDIR _MOCK_WORKDIR _ORIG_PATH
}

# Run devdash in the mock working directory
run_dd() {
  (cd "$_MOCK_WORKDIR" && "$DEVDASH" "$@")
}

test_summary() {
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  if [ "$FAIL" -gt 0 ]; then
    exit 1
  fi
}
