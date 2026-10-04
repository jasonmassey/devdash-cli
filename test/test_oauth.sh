#!/usr/bin/env bash

echo "-- browser OAuth code exchange --"

REAL_CURL=$(type -P curl)

start_oauth_login() {
  rm -f "$DD_TOKEN_FILE"
  run_dd login --no-browser > "${_MOCK_TMPDIR}/login-output" 2>&1 &
  login_pid=$!
  local attempt
  for attempt in {1..100}; do
    login_url=$(grep -Eo 'https?://[^[:space:]]+/api/auth/cli-token[^[:space:]]*' "${_MOCK_TMPDIR}/login-output" | head -1 || true)
    [ -n "$login_url" ] && break
    if ! kill -0 "$login_pid" 2>/dev/null; then break; fi
    sleep 0.05
  done
  login_port=$(printf '%s' "$login_url" | sed -nE 's/.*[?&]port=([0-9]+).*/\1/p')
  login_nonce=$(printf '%s' "$login_url" | sed -nE 's/.*[?&]nonce=([0-9a-f]+).*/\1/p')
  login_challenge=$(printf '%s' "$login_url" | sed -nE 's/.*[?&]code_challenge=([A-Za-z0-9_-]+).*/\1/p')
}

finish_oauth_login() {
  local attempt
  for attempt in {1..100}; do
    if ! kill -0 "$login_pid" 2>/dev/null; then break; fi
    sleep 0.05
  done
  if kill -0 "$login_pid" 2>/dev/null; then
    kill "$login_pid" 2>/dev/null || true
    fail "browser login completed promptly"
  else
    pass "browser login completed promptly"
  fi
  set +e
  wait "$login_pid"
  login_exit=$?
  set -e
}

setup_api_test
mkdir -p "${_MOCK_TMPDIR}/oauth-fixtures"
printf '{"token":"dd_%s"}\n' "$(printf 'a%.0s' {1..64})" > "${_MOCK_TMPDIR}/oauth-fixtures/POST_auth_cli_exchange.json"
export MOCK_CURL_FIXTURE_DIR="${_MOCK_TMPDIR}/oauth-fixtures"
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
original_devdash="$DEVDASH"
ln -s "$DEVDASH" "${_MOCK_TMPDIR}/devdash-symlink"
DEVDASH="${_MOCK_TMPDIR}/devdash-symlink"
start_oauth_login
DEVDASH="$original_devdash"
if [ "${#login_challenge}" -eq 43 ] && [ -n "$login_port" ] && [ -n "$login_nonce" ]; then
  pass "browser URL has a PKCE challenge and loopback callback"
else
  fail "browser URL has a PKCE challenge and loopback callback"
fi
if [[ "$login_url" != *dd_* ]]; then pass "browser URL has no API token"; else fail "browser URL has no API token"; fi

callback_url="http://127.0.0.1:${login_port}/callback"
status=$("$REAL_CURL" -q -s --max-time 3 -o /dev/null -w '%{http_code}' "${callback_url}?token=dd_oldtoken&nonce=${login_nonce}")
[ "$status" = "400" ] && pass "callback refuses token URL" || fail "callback refuses token URL"
status=$("$REAL_CURL" -q -s --max-time 3 -o /dev/null -w '%{http_code}' "${callback_url}?code=$(printf 'c%.0s' {1..48})&nonce=wrong")
[ "$status" = "400" ] && pass "callback refuses wrong nonce" || fail "callback refuses wrong nonce"
if [ ! -f "$DD_TOKEN_FILE" ]; then pass "rejected callbacks save no token"; else fail "rejected callbacks save no token"; fi
status=$("$REAL_CURL" -q -s --max-time 3 -o /dev/null -w '%{http_code}' "${callback_url}?code=$(printf 'c%.0s' {1..48})&nonce=${login_nonce}")
[ "$status" = "200" ] && pass "code-only callback accepted" || fail "code-only callback accepted"
finish_oauth_login
[ "$login_exit" -eq 0 ] && pass "code exchange completes browser login" || fail "code exchange completes browser login"
assert_api_called "one-time code exchanged by POST" "POST" "/auth/cli/exchange"
assert_contains "exchange request prevents redirects" "POST http://localhost:9999/api/auth/cli/exchange redirects=0 config=disabled" cat "${MOCK_CURL_LOG}.security"
if [ -f "$DD_TOKEN_FILE" ] && [ "$(cat "$DD_TOKEN_FILE")" = "dd_$(printf 'a%.0s' {1..64})" ]; then
  pass "only exchanged token saved"
else
  fail "only exchanged token saved"
fi
assert_not_contains "login output has no token" "dd_$(printf 'a%.0s' {1..64})" cat "${_MOCK_TMPDIR}/login-output"
exchange_body="${MOCK_CURL_LOG}.exchange-body"
if jq -e --arg uri "$callback_url" --arg nonce "$login_nonce" --arg code "$(printf 'c%.0s' {1..48})" \
  '.redirect_uri == $uri and .nonce == $nonce and .code == $code and (.code_verifier | test("^[A-Za-z0-9._~-]{43,128}$"))' "$exchange_body" >/dev/null; then
  pass "exchange binds code, callback and nonce to verifier"
else
  fail "exchange binds code, callback and nonce to verifier"
fi
verifier=$(jq -r '.code_verifier' "$exchange_body")
recomputed=$(printf '%s' "$verifier" | openssl dgst -binary -sha256 | openssl base64 -A | tr '+/' '-_' | tr -d '=\n')
[ "$recomputed" = "$login_challenge" ] && pass "PKCE challenge matches verifier" || fail "PKCE challenge matches verifier"
teardown_api_test
unset MOCK_CURL_REDIRECT

setup_api_test
mkdir -p "${_MOCK_TMPDIR}/oauth-fixtures"
printf '{"error":"expired"}\n' > "${_MOCK_TMPDIR}/oauth-fixtures/POST_auth_cli_exchange.json"
printf '401\n' > "${_MOCK_TMPDIR}/oauth-fixtures/POST_auth_cli_exchange.status"
export MOCK_CURL_FIXTURE_DIR="${_MOCK_TMPDIR}/oauth-fixtures"
start_oauth_login
callback_url="http://127.0.0.1:${login_port}/callback"
"$REAL_CURL" -q -s --max-time 3 -o /dev/null "${callback_url}?code=$(printf 'd%.0s' {1..48})&nonce=${login_nonce}"
finish_oauth_login
[ "$login_exit" -eq 2 ] && pass "expired or replayed code fails login" || fail "expired or replayed code fails login"
if [ ! -f "$DD_TOKEN_FILE" ]; then pass "failed exchange saves no token"; else fail "failed exchange saves no token"; fi
teardown_api_test
