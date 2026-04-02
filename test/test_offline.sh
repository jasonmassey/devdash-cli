#!/usr/bin/env bash
# Offline tests — no API calls, no mock curl needed

echo "=== Offline tests ==="
echo ""

# ── Version ──────────────────────────────────────────
echo "-- version --"
expected_version=$(jq -r '.version' "$(dirname "${BASH_SOURCE[0]}")/../package.json")
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
assert_contains "help lists agent-setup"    "agent-setup"    "$DEVDASH" help
assert_contains "help lists doctor"         "doctor"         "$DEVDASH" help
assert_contains "help lists alias-setup"    "alias-setup"    "$DEVDASH" help
assert_contains "help lists self-update"    "self-update"    "$DEVDASH" help
assert_contains "help lists project create" "project create" "$DEVDASH" help
assert_contains "help lists project list"   "project list"   "$DEVDASH" help
assert_contains "help lists project delete" "project delete" "$DEVDASH" help
assert_contains "help lists reconcile"      "reconcile"      "$DEVDASH" help
assert_contains "help cli guides ready for task choice" "Use this when you need to choose what to work on next." "$DEVDASH" help cli
assert_contains "help cli guides show for named issue" "Start here when the user already named the issue." "$DEVDASH" help cli

# ── Doctor ───────────────────────────────────────────
echo "-- doctor --"
assert_contains "doctor checks curl"     "curl"     "$DEVDASH" doctor
assert_contains "doctor checks jq"       "jq"       "$DEVDASH" doctor
assert_contains "doctor checks openssl"  "openssl"  "$DEVDASH" doctor
assert_contains "doctor checks python3"  "python3"  "$DEVDASH" doctor
assert_contains "doctor checks git"      "git"      "$DEVDASH" doctor
assert_contains "doctor checks token"    "token"    "$DEVDASH" doctor

# ── Agent Setup ─────────────────────────────────────
echo "-- agent-setup --"
_agent_dir="$(mktemp -d)"
echo '{"project_id":"test"}' > "${_agent_dir}/.devdash"
(
  cd "$_agent_dir" || exit 1
  "$DEVDASH" agent-setup --all --force >/dev/null 2>&1
)
for _af in CLAUDE.md AGENTS.md .windsurfrules .clinerules .cursor/rules/devdash.mdc .github/copilot-instructions.md; do
  if [ -f "${_agent_dir}/${_af}" ]; then
    pass "agent-setup creates ${_af}"
  else
    fail "agent-setup creates ${_af} (file not found)"
  fi
done
if grep -qF "devdash:agent-instructions" "${_agent_dir}/CLAUDE.md" 2>/dev/null; then
  pass "agent config contains marker"
else
  fail "agent config contains marker"
fi
if grep -qF "Run \`devdash prime\` at the start of every new session." "${_agent_dir}/AGENTS.md" 2>/dev/null; then
  pass "codex config contains custom guidance"
else
  fail "codex config contains custom guidance"
fi
if grep -qF "Before each commit, confirm that the commit maps to exactly one devdash issue." "${_agent_dir}/AGENTS.md" 2>/dev/null; then
  pass "codex config contains commit guidance"
else
  fail "codex config contains commit guidance"
fi
if grep -qF "Run the narrowest verification that meaningfully covers the change, then summarize the result for the user." "${_agent_dir}/AGENTS.md" 2>/dev/null; then
  pass "codex config contains verification guidance"
else
  fail "codex config contains verification guidance"
fi
_skip_output=$(cd "$_agent_dir" && "$DEVDASH" agent-setup --all 2>&1)
if echo "$_skip_output" | grep -qF "already configured"; then
  pass "agent-setup skips existing (idempotent)"
else
  fail "agent-setup skips existing (idempotent)"
fi
_force_output=$(cd "$_agent_dir" && "$DEVDASH" agent-setup --all --force 2>&1)
if echo "$_force_output" | grep -qF "wrote:"; then
  pass "agent-setup --force overwrites"
else
  fail "agent-setup --force overwrites"
fi
rm -rf "$_agent_dir"

# ── Prime ────────────────────────────────────────────
echo "-- prime --"
_prime_dir="$(mktemp -d)"
echo '{"project_id":"test"}' > "${_prime_dir}/.devdash"
assert_contains "prime shows named-task start flow" 'Start (task already named)' bash -c "cd '$_prime_dir' && '$DEVDASH' prime"
assert_contains "prime shows ready flow for task selection" 'Start (need a task)' bash -c "cd '$_prime_dir' && '$DEVDASH' prime"
rm -rf "$_prime_dir"

# ── Priority validation ─────────────────────────────
echo "-- priority validation --"
_pv_dir="$(mktemp -d)"
echo '{"project_id":"test","api_url":"http://localhost:9999"}' > "${_pv_dir}/.devdash"
_pv_config="$(mktemp -d)"
echo "mock-token" > "${_pv_config}/token"
_pv_env="env DD_CONFIG_DIR=$_pv_config DD_TOKEN_FILE=${_pv_config}/token"

assert_exit "create --priority=5 exits 1" 1 \
  env DD_CONFIG_DIR="$_pv_config" DD_TOKEN_FILE="${_pv_config}/token" \
  bash -c "cd '$_pv_dir' && '$DEVDASH' create --title='test' --priority=5"
assert_contains "create --priority=5 shows error" "priority must be 0-4" \
  env DD_CONFIG_DIR="$_pv_config" DD_TOKEN_FILE="${_pv_config}/token" \
  bash -c "cd '$_pv_dir' && '$DEVDASH' create --title='test' --priority=5"

assert_exit "create --priority=abc exits 1" 1 \
  env DD_CONFIG_DIR="$_pv_config" DD_TOKEN_FILE="${_pv_config}/token" \
  bash -c "cd '$_pv_dir' && '$DEVDASH' create --title='test' --priority=abc"
assert_contains "create --priority=abc shows error" "priority must be 0-4" \
  env DD_CONFIG_DIR="$_pv_config" DD_TOKEN_FILE="${_pv_config}/token" \
  bash -c "cd '$_pv_dir' && '$DEVDASH' create --title='test' --priority=abc"

assert_exit "create --priority=-1 exits 1" 1 \
  env DD_CONFIG_DIR="$_pv_config" DD_TOKEN_FILE="${_pv_config}/token" \
  bash -c "cd '$_pv_dir' && '$DEVDASH' create --title='test' --priority=-1"

rm -rf "$_pv_dir" "$_pv_config"

# ── HTTPS enforcement ──────────────────────────────
echo "-- HTTPS enforcement --"
_https_dir="$(mktemp -d)"
_https_config="$(mktemp -d)"
echo "mock-token" > "${_https_config}/token"

# HTTP non-localhost should warn
echo '{"project_id":"test","api_url":"http://example.com"}' > "${_https_dir}/.devdash"
assert_contains "HTTP non-localhost warns" "insecure HTTP" \
  env DD_CONFIG_DIR="$_https_config" DD_TOKEN_FILE="${_https_config}/token" \
  bash -c "cd '$_https_dir' && '$DEVDASH' list 2>&1"

# HTTP localhost should NOT warn
echo '{"project_id":"test","api_url":"http://localhost:9999"}' > "${_https_dir}/.devdash"
assert_not_contains "HTTP localhost no warning" "insecure HTTP" \
  env DD_CONFIG_DIR="$_https_config" DD_TOKEN_FILE="${_https_config}/token" \
  bash -c "cd '$_https_dir' && '$DEVDASH' list 2>&1"

# HTTPS should NOT warn
echo '{"project_id":"test","api_url":"https://example.com"}' > "${_https_dir}/.devdash"
assert_not_contains "HTTPS no warning" "insecure HTTP" \
  env DD_CONFIG_DIR="$_https_config" DD_TOKEN_FILE="${_https_config}/token" \
  bash -c "cd '$_https_dir' && '$DEVDASH' list 2>&1"

rm -rf "$_https_dir" "$_https_config"

# ── Error handling ───────────────────────────────────
echo "-- error handling --"
assert_exit "unknown command exits 1"     1 "$DEVDASH" xyzzy
assert_contains "unknown command message" "Unknown command" "$DEVDASH" xyzzy
assert_exit "show without args exits 1"   1 "$DEVDASH" show
# create calls dd_project_id() before checking title, so run in a dir with .devdash
_err_dir="$(mktemp -d)"
echo '{"project_id":"test","api_url":"http://localhost:9999"}' > "${_err_dir}/.devdash"
_err_config="$(mktemp -d)"
echo "mock-token" > "${_err_config}/token"
assert_exit "create without title exits 1" 1 \
  env DD_CONFIG_DIR="$_err_config" DD_TOKEN_FILE="${_err_config}/token" bash -c "cd '$_err_dir' && '$DEVDASH' create"
rm -rf "$_err_dir" "$_err_config"
assert_exit "delete without args exits 1" 1 "$DEVDASH" delete

# ── Unauthenticated ─────────────────────────────────
echo "-- unauthenticated access --"
_tmp_dir="$(mktemp -d)"
echo '{"project_id":"test","api_url":"http://localhost:9999"}' > "${_tmp_dir}/.devdash"
_tmp_config_dir="$(mktemp -d)"
_tmp_token_file="${_tmp_config_dir}/token"
assert_contains "no-token shows login prompt" "devdash login" \
  env DD_CONFIG_DIR="$_tmp_config_dir" DD_TOKEN_FILE="$_tmp_token_file" bash -c "cd '$_tmp_dir' && '$DEVDASH' list"
assert_exit "no-token exits 3 (config error)" 3 \
  env DD_CONFIG_DIR="$_tmp_config_dir" DD_TOKEN_FILE="$_tmp_token_file" bash -c "cd '$_tmp_dir' && '$DEVDASH' list"
rm -rf "$_tmp_dir" "$_tmp_config_dir"
