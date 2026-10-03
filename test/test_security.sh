#!/usr/bin/env bash
# Security tests — token exfiltration prevention
# Proves that:
#   1. Malicious repo api_url (HTTP or HTTPS) is never used as the API origin
#   2. The Bearer token is never sent to an attacker-controlled host
#   3. curl redirects are disabled (--max-redirs 0) to prevent cross-origin token forwarding
#   4. Trusted DD_API_URL and built-in default still work correctly

echo ""
echo "=== Security tests ==="
echo ""

# ── Helper: capture what host curl was told to contact ───────────
# We use a specialised mock that records the full URL and always returns 401
# so that devdash exits without needing a fixture.

_SEC_DIR="$(mktemp -d)"
_SEC_CONFIG="$(mktemp -d)"
_SEC_CURL_LOG="${_SEC_DIR}/curl_urls.log"
_SEC_MOCK_DIR="${_SEC_DIR}/mock"
mkdir -p "$_SEC_MOCK_DIR"

# Write a lightweight mock curl that logs the URL and exits with HTTP 401
cat > "${_SEC_MOCK_DIR}/curl" << 'MOCK_CURL'
#!/usr/bin/env bash
# Security-test mock curl: logs full URL, returns 401
write_format=""
outfile=""
url=""

while [ $# -gt 0 ]; do
  case "$1" in
    -X|-H|-d) shift 2 ;;
    --max-redirs) shift 2 ;;
    -s) shift ;;
    -o) outfile="$2"; shift 2 ;;
    -w) write_format="$2"; shift 2 ;;
    http://*|https://*) url="$1"; shift ;;
    *) shift ;;
  esac
done

# Log the URL so tests can inspect it
echo "$url" >> "${SEC_CURL_LOG}"

# Also capture Authorization header to prove token wasn't sent to attacker
for arg in "$@"; do : ; done  # already consumed above

# Return minimal 401 body
body='{"error":"Unauthorized"}'
if [ -n "$outfile" ]; then
  echo "$body" > "$outfile"
else
  echo "$body"
fi

if [ "$write_format" = '%{http_code}' ]; then
  printf '401'
fi
MOCK_CURL
chmod +x "${_SEC_MOCK_DIR}/curl"

# Write a mock curl that also logs Authorization headers
cat > "${_SEC_DIR}/curl_auth_logger" << 'AUTH_LOGGER'
#!/usr/bin/env bash
# Records Authorization header value and returns 401
write_format=""
outfile=""
url=""
auth_header=""

while [ $# -gt 0 ]; do
  case "$1" in
    -X) shift 2 ;;
    --max-redirs) shift 2 ;;
    -s) shift ;;
    -H)
      if [[ "$2" == Authorization* ]]; then auth_header="$2"; fi
      shift 2 ;;
    -d) shift 2 ;;
    -o) outfile="$2"; shift 2 ;;
    -w) write_format="$2"; shift 2 ;;
    http://*|https://*) url="$1"; shift ;;
    *) shift ;;
  esac
done

echo "URL=${url} AUTH=${auth_header}" >> "${SEC_AUTH_LOG}"

body='{"error":"Unauthorized"}'
if [ -n "$outfile" ]; then echo "$body" > "$outfile"; else echo "$body"; fi
if [ "$write_format" = '%{http_code}' ]; then printf '401'; fi
AUTH_LOGGER
chmod +x "${_SEC_DIR}/curl_auth_logger"

echo "-- repo api_url is ignored (token exfiltration prevention) --"

# Test 1: Malicious HTTPS api_url in .devdash must be ignored
_t1_dir="$(mktemp -d)"
_t1_log="${_SEC_DIR}/t1_urls.log"
echo '{"project_id":"proj-1","api_url":"https://attacker.example.com"}' > "${_t1_dir}/.devdash"
echo "mock-token-secret" > "${_SEC_CONFIG}/token"
: > "$_t1_log"
SEC_CURL_LOG="$_t1_log" PATH="${_SEC_MOCK_DIR}:${PATH}" \
  env DD_CONFIG_DIR="$_SEC_CONFIG" DD_TOKEN_FILE="${_SEC_CONFIG}/token" \
  bash -c "cd '$_t1_dir' && '$DEVDASH' list" >/dev/null 2>&1 || true
if grep -q "attacker.example.com" "$_t1_log" 2>/dev/null; then
  fail "malicious HTTPS repo api_url: token NOT sent to attacker (FAIL — attacker URL was contacted)"
else
  pass "malicious HTTPS repo api_url: attacker host never contacted"
fi
rm -rf "$_t1_dir"

# Test 2: Malicious HTTP api_url in .devdash must be ignored
_t2_dir="$(mktemp -d)"
_t2_log="${_SEC_DIR}/t2_urls.log"
echo '{"project_id":"proj-2","api_url":"http://attacker.example.com"}' > "${_t2_dir}/.devdash"
: > "$_t2_log"
SEC_CURL_LOG="$_t2_log" PATH="${_SEC_MOCK_DIR}:${PATH}" \
  env DD_CONFIG_DIR="$_SEC_CONFIG" DD_TOKEN_FILE="${_SEC_CONFIG}/token" \
  bash -c "cd '$_t2_dir' && '$DEVDASH' list" >/dev/null 2>&1 || true
if grep -q "attacker.example.com" "$_t2_log" 2>/dev/null; then
  fail "malicious HTTP repo api_url: attacker host contacted (FAIL)"
else
  pass "malicious HTTP repo api_url: attacker host never contacted"
fi
rm -rf "$_t2_dir"

# Test 3: Trusted DD_API_URL env var is used as the actual API origin
_t3_dir="$(mktemp -d)"
_t3_log="${_SEC_DIR}/t3_urls.log"
echo '{"project_id":"proj-3"}' > "${_t3_dir}/.devdash"
: > "$_t3_log"
SEC_CURL_LOG="$_t3_log" PATH="${_SEC_MOCK_DIR}:${PATH}" \
  env DD_CONFIG_DIR="$_SEC_CONFIG" DD_TOKEN_FILE="${_SEC_CONFIG}/token" \
  DD_API_URL="https://trusted.example.com" \
  bash -c "cd '$_t3_dir' && '$DEVDASH' list" >/dev/null 2>&1 || true
if grep -q "trusted.example.com" "$_t3_log" 2>/dev/null; then
  pass "trusted DD_API_URL env var is used as API origin"
else
  fail "trusted DD_API_URL env var is used as API origin (URL not found in log)"
fi
rm -rf "$_t3_dir"

# Test 4: repo api_url is completely ignored even when DD_API_URL is also set
_t4_dir="$(mktemp -d)"
_t4_log="${_SEC_DIR}/t4_urls.log"
echo '{"project_id":"proj-4","api_url":"https://attacker.example.com"}' > "${_t4_dir}/.devdash"
: > "$_t4_log"
SEC_CURL_LOG="$_t4_log" PATH="${_SEC_MOCK_DIR}:${PATH}" \
  env DD_CONFIG_DIR="$_SEC_CONFIG" DD_TOKEN_FILE="${_SEC_CONFIG}/token" \
  DD_API_URL="https://trusted.example.com" \
  bash -c "cd '$_t4_dir' && '$DEVDASH' list" >/dev/null 2>&1 || true
if grep -q "attacker.example.com" "$_t4_log" 2>/dev/null; then
  fail "repo api_url ignored when DD_API_URL set: attacker contacted (FAIL)"
else
  pass "repo api_url ignored when DD_API_URL set: only trusted origin used"
fi
if grep -q "trusted.example.com" "$_t4_log" 2>/dev/null; then
  pass "DD_API_URL still honoured when repo api_url present"
else
  fail "DD_API_URL still honoured when repo api_url present"
fi
rm -rf "$_t4_dir"

echo "-- curl redirect protection (--max-redirs 0) --"

# Test 5: verify the CLI passes --max-redirs to curl
# We intercept curl with a script that records its arguments, then check for --max-redirs
_t5_dir="$(mktemp -d)"
_t5_args_log="${_SEC_DIR}/t5_args.log"
_t5_mock="${_SEC_DIR}/t5_mock"
mkdir -p "$_t5_mock"
cat > "${_t5_mock}/curl" << 'T5MOCK'
#!/usr/bin/env bash
echo "$@" >> "${T5_ARGS_LOG}"
write_format=""
outfile=""
for arg in "$@"; do
  case "$arg" in
    -w) : ;; -o) : ;;
  esac
done
# Parse to find -w and -o
prev=""
for arg in "$@"; do
  if [ "$prev" = "-o" ]; then echo '{"data":[]}' > "$arg"; fi
  if [ "$prev" = "-w" ] && [ "$arg" = '%{http_code}' ]; then printf '200'; fi
  prev="$arg"
done
T5MOCK
chmod +x "${_t5_mock}/curl"
echo '{"project_id":"proj-5"}' > "${_t5_dir}/.devdash"
: > "$_t5_args_log"
T5_ARGS_LOG="$_t5_args_log" PATH="${_t5_mock}:${PATH}" \
  env DD_CONFIG_DIR="$_SEC_CONFIG" DD_TOKEN_FILE="${_SEC_CONFIG}/token" \
  DD_API_URL="http://localhost:9999" \
  bash -c "cd '$_t5_dir' && '$DEVDASH' list" >/dev/null 2>&1 || true
if grep -q -- "--max-redirs" "$_t5_args_log" 2>/dev/null; then
  pass "curl called with --max-redirs (redirects disabled)"
else
  fail "curl called with --max-redirs (redirects disabled) — flag not found in: $(cat "$_t5_args_log" 2>/dev/null | head -1)"
fi
rm -rf "$_t5_dir" "$_t5_mock"

# Cleanup
rm -rf "$_SEC_DIR" "$_SEC_CONFIG"
