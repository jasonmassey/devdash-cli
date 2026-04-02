#!/usr/bin/env bash
# API command tests — uses mock curl to intercept HTTP calls

echo ""
echo "=== API tests ==="
echo ""

# ── list ─────────────────────────────────────────────
echo "-- list --"
setup_api_test

output=$(run_dd list 2>&1) || true
assert_contains "list shows pending bead"     "dev-dash-1" echo "$output"
assert_contains "list shows in_progress bead" "dev-dash-2" echo "$output"
assert_contains "list shows completed bead"   "dev-dash-4" echo "$output"
assert_contains "list shows thought bead"     "dev-dash-5" echo "$output"
assert_api_called "list calls GET /beads" "GET" "/beads"
teardown_api_test

# list --status=pending
setup_api_test
output=$(run_dd list --status=pending 2>&1) || true
assert_contains "list --status=pending shows pending" "dev-dash-1" echo "$output"
assert_not_contains "list --status=pending hides completed" "dev-dash-4" echo "$output"
teardown_api_test

# list --status=completed
setup_api_test
output=$(run_dd list --status=completed 2>&1) || true
assert_contains "list --status=completed shows completed" "dev-dash-4" echo "$output"
assert_not_contains "list --status=completed hides pending" "dev-dash-1" echo "$output"
teardown_api_test

# list with empty project
setup_api_test
_empty_dir=$(mktemp -d)
cp "${TEST_DIR}/fixtures/GET_beads_empty.json" "${_empty_dir}/GET_beads.json"
export MOCK_CURL_FIXTURE_DIR="$_empty_dir"
output=$(run_dd list 2>&1) || true
# With empty beads, output should be empty (no error)
assert_exit "list with empty project exits 0" 0 bash -c "cd '$_MOCK_WORKDIR' && '$DEVDASH' list"
rm -rf "$_empty_dir"
teardown_api_test

# ── ready ────────────────────────────────────────────
echo "-- ready --"
setup_api_test
output=$(run_dd ready 2>&1) || true
assert_contains "ready shows pending+unblocked" "dev-dash-1" echo "$output"
assert_not_contains "ready excludes blocked"    "dev-dash-3" echo "$output"
assert_not_contains "ready excludes completed"  "dev-dash-4" echo "$output"
assert_not_contains "ready excludes thoughts"   "dev-dash-5" echo "$output"
assert_not_contains "ready excludes in_progress" "dev-dash-2" echo "$output"
teardown_api_test

# ── blocked ──────────────────────────────────────────
echo "-- blocked --"
setup_api_test
output=$(run_dd blocked 2>&1) || true
assert_contains "blocked shows blocked bead"    "dev-dash-3" echo "$output"
assert_not_contains "blocked hides unblocked"   "dev-dash-1" echo "$output"
assert_not_contains "blocked hides completed"   "dev-dash-4" echo "$output"
teardown_api_test

# ── show ─────────────────────────────────────────────
echo "-- show --"
setup_api_test
output=$(run_dd show aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "show displays subject"      "Implement auth flow" echo "$output"
assert_contains "show displays status"       "pending" echo "$output"
assert_contains "show displays priority"     "1" echo "$output"
assert_contains "show displays beadType"     "task" echo "$output"
assert_api_called "show calls GET /beads/ID" "GET" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
teardown_api_test

# show missing ID
assert_exit "show without ID exits 1" 1 "$DEVDASH" show

# ── create ───────────────────────────────────────────
echo "-- create --"
setup_api_test
output=$(run_dd create --title="Test task" --type=bug --priority=1 --description="Fix it" 2>&1) || true
assert_contains "create shows Created"     "Created" echo "$output"
assert_contains "create shows bead ID"     "ffffffff" echo "$output"
assert_api_called "create calls POST /beads" "POST" "/beads"
assert_api_body "create body has subject"  "POST" "/beads" '"subject"'
assert_api_body "create body has beadType" "POST" "/beads" '"beadType"'
teardown_api_test

# create with positional title
setup_api_test
output=$(run_dd create "Positional title" 2>&1) || true
assert_contains "create with positional title works" "Created" echo "$output"
assert_api_body "create positional has subject" "POST" "/beads" "Positional title"
teardown_api_test

# create missing title (run_dd provides .devdash + token context)
setup_api_test
assert_exit "create without title exits 1" 1 run_dd create
teardown_api_test

# create help does not call API
setup_api_test
output=$(run_dd create --help 2>&1) || true
assert_contains "create --help prints usage" 'Usage: devdash create --title="..."' echo "$output"
if [ ! -s "$MOCK_CURL_LOG" ]; then
  pass "create --help skips API call"
else
  fail "create --help skips API call"
fi
teardown_api_test

setup_api_test
output=$(run_dd create -h 2>&1) || true
assert_contains "create -h prints usage" 'Usage: devdash create --title="..."' echo "$output"
if [ ! -s "$MOCK_CURL_LOG" ]; then
  pass "create -h skips API call"
else
  fail "create -h skips API call"
fi
teardown_api_test

# ── update ───────────────────────────────────────────
echo "-- update --"
setup_api_test
output=$(run_dd update aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --status=in_progress 2>&1) || true
assert_contains "update shows Updated"       "Updated" echo "$output"
assert_api_called "update calls PATCH /beads" "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
assert_api_body "update body has status"     "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" '"status"'
teardown_api_test

# update with priority
setup_api_test
output=$(run_dd update aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --priority=0 2>&1) || true
assert_contains "update --priority works" "Updated" echo "$output"
assert_api_body "update body has priority" "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" '"priority"'
teardown_api_test

# update with invalid priority
setup_api_test
assert_exit "update --priority=5 exits 1" 1 run_dd update aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --priority=5
output=$(run_dd update aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --priority=5 2>&1) || true
assert_contains "update --priority=5 shows error" "priority must be 0-4" echo "$output"
teardown_api_test

setup_api_test
assert_exit "update --priority=abc exits 1" 1 run_dd update aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --priority=abc
teardown_api_test

# update with title
setup_api_test
output=$(run_dd update aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --title="New title" 2>&1) || true
assert_contains "update --title works" "Updated" echo "$output"
assert_api_body "update body has subject" "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" '"subject"'
teardown_api_test

# ── close ────────────────────────────────────────────
echo "-- close --"
setup_api_test
output=$(run_dd close aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "close shows Closed"       "Closed" echo "$output"
assert_api_called "close calls PATCH"      "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
assert_api_body "close body has completed" "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" '"completed"'
teardown_api_test

# close with metadata flags
setup_api_test
output=$(run_dd close aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --pr=https://github.com/pr/1 --commit=abc123 --summary="Done" 2>&1) || true
assert_contains "close with metadata shows Closed" "Closed" echo "$output"
assert_api_body "close body has prUrl"    "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" "prUrl"
assert_api_body "close body has commitSha" "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" "commitSha"
assert_api_body "close body has summary"  "PATCH" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" '"summary"'
teardown_api_test

# close missing ID
assert_exit "close without ID exits 1" 1 "$DEVDASH" close

# ── stale ────────────────────────────────────────────
echo "-- stale --"
setup_api_test
output=$(run_dd stale 2>&1) || true
assert_contains "stale shows stale bead"        "dev-dash-2" echo "$output"
assert_contains "stale shows stale minutes"     "4320" echo "$output"
assert_not_contains "stale hides non-stale"     "dev-dash-1" echo "$output"
teardown_api_test

# stale with no stale beads
setup_api_test
_nostale_dir=$(mktemp -d)
# Create fixture with no in_progress beads that have staleMinutes
cat > "${_nostale_dir}/GET_beads.json" << 'FIXTURE'
{
  "data": [
    {
      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "localBeadId": "dev-dash-1",
      "subject": "Fresh task",
      "status": "in_progress",
      "priority": 1,
      "beadType": "task",
      "blockedBy": [],
      "blocks": [],
      "staleMinutes": null,
      "staleSince": null
    }
  ],
  "nextCursor": null
}
FIXTURE
export MOCK_CURL_FIXTURE_DIR="$_nostale_dir"
output=$(run_dd stale 2>&1) || true
assert_contains "stale with none shows message" "No stale" echo "$output"
rm -rf "$_nostale_dir"
teardown_api_test

# ── stats ────────────────────────────────────────────
echo "-- stats --"
setup_api_test
output=$(run_dd stats 2>&1) || true
assert_contains "stats shows total"       "Total:       5" echo "$output"
assert_contains "stats shows pending"     "Pending:     3" echo "$output"
assert_contains "stats shows in_progress" "In Progress: 1" echo "$output"
assert_contains "stats shows completed"   "Completed:   1" echo "$output"
teardown_api_test

# ── delete ───────────────────────────────────────────
echo "-- delete --"
# delete missing ID
assert_exit "delete without ID exits 1" 1 "$DEVDASH" delete

# delete with --force (skips interactive prompt)
setup_api_test
output=$(run_dd delete --force aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "delete --force shows Deleted" "Deleted" echo "$output"
assert_api_called "delete calls DELETE /beads" "DELETE" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
# Verify delete URL does NOT include projectId (regression: caused 404)
if grep -F "DELETE" "${MOCK_CURL_LOG}.urls" | grep -qF "projectId"; then
  fail "delete URL excludes projectId (found projectId in URL)"
else
  pass "delete URL excludes projectId"
fi
teardown_api_test

# delete --cascade includes cascade in URL
setup_api_test
output=$(run_dd delete --force --cascade aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "delete --cascade shows Deleted" "Deleted" echo "$output"
if grep -F "DELETE" "${MOCK_CURL_LOG}.urls" | grep -qF "cascade=true"; then
  pass "delete --cascade URL includes cascade param"
else
  fail "delete --cascade URL includes cascade param"
fi
teardown_api_test

# ── dep add ──────────────────────────────────────────
echo "-- dep add --"
setup_api_test
output=$(run_dd dep add aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb 2>&1) || true
assert_contains "dep add shows confirmation" "Added dependency" echo "$output"
assert_api_called "dep add posts to dependencies" "POST" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/dependencies"
assert_api_body "dep add body has blockedBy" "POST" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/dependencies" "blockedBy"
teardown_api_test

# dep add missing args
setup_api_test
assert_exit "dep add without args exits 1" 1 run_dd dep add
teardown_api_test

# ── dep remove ──────────────────────────────────────
echo "-- dep remove --"
setup_api_test
output=$(run_dd dep remove aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb 2>&1) || true
assert_contains "dep remove shows confirmation" "Removed dependency" echo "$output"
assert_api_called "dep remove calls DELETE" "DELETE" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/dependencies/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
teardown_api_test

# dep remove missing args
setup_api_test
assert_exit "dep remove without args exits 1" 1 run_dd dep remove
teardown_api_test

# ── project list ─────────────────────────────────────
echo "-- project list --"
setup_api_test
output=$(run_dd project list 2>&1) || true
assert_contains "project list shows project"    "devdash-cli" echo "$output"
assert_contains "project list shows other"      "other-project" echo "$output"
assert_api_called "project list calls GET"      "GET" "/projects"
teardown_api_test

# ── project create ───────────────────────────────────
echo "-- project create --"
setup_api_test
output=$(run_dd project create --name="Test Project" 2>&1) || true
assert_contains "project create shows Created"  "Created project" echo "$output"
assert_api_called "project create calls POST"   "POST" "/projects"
assert_api_body "project create body has name"  "POST" "/projects" "Test Project"
teardown_api_test

# project create missing name
assert_exit "project create without name exits 1" 1 "$DEVDASH" project create

# ── project delete ───────────────────────────────────
echo "-- project delete --"
setup_api_test
output=$(run_dd project delete --force 95ca3de0-7e4f-4f9e-9b17-36f5609cfa11 2>&1) || true
assert_contains "project delete shows Deleted" "Deleted project" echo "$output"
assert_api_called "project delete calls DELETE" "DELETE" "/projects/95ca3de0-7e4f-4f9e-9b17-36f5609cfa11"
teardown_api_test

# project delete missing ID
assert_exit "project delete without ID exits 1" 1 "$DEVDASH" project delete

# ── comment ──────────────────────────────────────────
echo "-- comment --"
setup_api_test
output=$(run_dd comment aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa --body="Test comment" 2>&1) || true
assert_contains "comment shows confirmation" "Comment added" echo "$output"
assert_api_called "comment calls POST" "POST" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/comments"
assert_api_body "comment body has content" "POST" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/comments" "Test comment"
teardown_api_test

# comment missing args
setup_api_test
assert_exit "comment without ID exits 1" 1 run_dd comment
teardown_api_test

setup_api_test
assert_exit "comment without body exits 1" 1 run_dd comment aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
teardown_api_test

# ── comments ────────────────────────────────────────
echo "-- comments --"
setup_api_test
output=$(run_dd comments aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "comments shows first comment" "First comment" echo "$output"
assert_contains "comments shows author" "Jason" echo "$output"
assert_contains "comments shows agent reply" "Agent reply" echo "$output"
assert_api_called "comments calls GET" "GET" "/beads/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/comments"
teardown_api_test

# comments missing ID
setup_api_test
assert_exit "comments without ID exits 1" 1 run_dd comments
teardown_api_test

# ── activity ────────────────────────────────────────
echo "-- activity --"
setup_api_test
output=$(run_dd activity 2>&1) || true
assert_contains "activity shows action" "created" echo "$output"
assert_contains "activity shows actor" "Jason" echo "$output"
assert_contains "activity shows artifact" "Test task" echo "$output"
assert_api_called "activity calls GET" "GET" "/projects/95ca3de0-7e4f-4f9e-9b17-36f5609cfa11/activity"
teardown_api_test

# ── bulk close ──────────────────────────────────────
echo "-- bulk close --"
setup_api_test
output=$(run_dd close aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb 2>&1) || true
assert_contains "bulk close shows first closed" "Closed: aaaaaaaa" echo "$output"
assert_contains "bulk close shows second closed" "Closed: bbbbbbbb" echo "$output"
assert_api_called "bulk close calls POST bulk" "POST" "/beads/bulk/close"
teardown_api_test

# ── list --parent ───────────────────────────────────
echo "-- list --parent --"
setup_api_test
# dev-dash-1 (aaaaaaaa) has no parentBeadId in fixture, so filtering by a different parent should exclude it
output=$(run_dd list --parent=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
# The fixture beads don't have parentBeadId set to aaaaaaaa, so result should be empty/filtered
assert_not_contains "list --parent filters out non-children" "dev-dash-1" echo "$output"
teardown_api_test

# ── Error responses ──────────────────────────────────
echo "-- API error responses --"

# 401 Unauthorized
setup_api_test
_err_dir=$(mktemp -d)
cp "${TEST_DIR}/fixtures/error_401.json" "${_err_dir}/GET_beads.json"
echo "401" > "${_err_dir}/GET_beads.status"
export MOCK_CURL_FIXTURE_DIR="$_err_dir"
output=$(run_dd list 2>&1) || true
assert_contains "401 shows Unauthorized"  "Unauthorized" echo "$output"
set +e; (cd "$_MOCK_WORKDIR" && "$DEVDASH" list >/dev/null 2>&1); code=$?; set -e
if [ "$code" -eq 2 ]; then pass "401 exits 2"; else fail "401 exits 2 (got $code)"; fi
rm -rf "$_err_dir"
teardown_api_test

# 404 Not found
setup_api_test
_err_dir=$(mktemp -d)
cp "${TEST_DIR}/fixtures/error_404.json" "${_err_dir}/GET_beads.json"
echo "404" > "${_err_dir}/GET_beads.status"
export MOCK_CURL_FIXTURE_DIR="$_err_dir"
output=$(run_dd list 2>&1) || true
assert_contains "404 shows Not found" "Not found" echo "$output"
set +e; (cd "$_MOCK_WORKDIR" && "$DEVDASH" list >/dev/null 2>&1); code=$?; set -e
if [ "$code" -eq 2 ]; then pass "404 exits 2"; else fail "404 exits 2 (got $code)"; fi
rm -rf "$_err_dir"
teardown_api_test

# 500 Internal server error
setup_api_test
_err_dir=$(mktemp -d)
cp "${TEST_DIR}/fixtures/error_500.json" "${_err_dir}/GET_beads.json"
echo "500" > "${_err_dir}/GET_beads.status"
export MOCK_CURL_FIXTURE_DIR="$_err_dir"
output=$(run_dd list 2>&1) || true
assert_contains "500 shows server error"  "Internal server error" echo "$output"
set +e; (cd "$_MOCK_WORKDIR" && "$DEVDASH" list >/dev/null 2>&1); code=$?; set -e
if [ "$code" -eq 2 ]; then pass "500 exits 2"; else fail "500 exits 2 (got $code)"; fi
rm -rf "$_err_dir"
teardown_api_test

# ── ID resolution ────────────────────────────────────
echo "-- ID resolution --"

# Full UUID
setup_api_test
output=$(run_dd show aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "full UUID resolves" "Implement auth flow" echo "$output"
teardown_api_test

# Short prefix
setup_api_test
output=$(run_dd show aaaaaaaa 2>&1) || true
assert_contains "short prefix resolves" "Implement auth flow" echo "$output"
teardown_api_test

# Local ID (dev-dash-*)
setup_api_test
output=$(run_dd show dev-dash-1 2>&1) || true
assert_contains "local ID resolves" "Implement auth flow" echo "$output"
teardown_api_test

# Not-found ID
setup_api_test
output=$(run_dd show nonexistent 2>&1) || true
assert_contains "not-found ID shows error" "not found" echo "$output"
teardown_api_test

# ── Config errors ────────────────────────────────────
echo "-- config errors --"

# Missing .devdash file
setup_api_test
rm -f "${_MOCK_WORKDIR}/.devdash"
set +e; (cd "$_MOCK_WORKDIR" && "$DEVDASH" list >/dev/null 2>&1); code=$?; set -e
if [ "$code" -eq 3 ]; then pass "missing .devdash exits 3"; else fail "missing .devdash exits 3 (got $code)"; fi
teardown_api_test

# Invalid .devdash JSON
setup_api_test
echo "not valid json" > "${_MOCK_WORKDIR}/.devdash"
set +e; (cd "$_MOCK_WORKDIR" && "$DEVDASH" list >/dev/null 2>&1); code=$?; set -e
if [ "$code" -eq 3 ]; then pass "invalid .devdash exits 3"; else fail "invalid .devdash exits 3 (got $code)"; fi
teardown_api_test

# ── jobs --bead ─────────────────────────────────────
echo "-- jobs --bead --"

# jobs --bead filters to matching bead
setup_api_test
output=$(run_dd jobs --bead=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "jobs --bead shows matching job" "11111111" echo "$output"
assert_contains "jobs --bead shows second matching job" "22222222" echo "$output"
assert_not_contains "jobs --bead hides other bead's jobs" "33333333" echo "$output"
teardown_api_test

# jobs --bead with local ID
setup_api_test
output=$(run_dd jobs --bead=dev-dash-1 2>&1) || true
assert_contains "jobs --bead with local ID works" "11111111" echo "$output"
assert_not_contains "jobs --bead local ID hides other" "33333333" echo "$output"
teardown_api_test

# jobs failures --bead filters failures by bead
setup_api_test
output=$(run_dd jobs failures --bead=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "jobs failures --bead shows failed job" "22222222" echo "$output"
assert_not_contains "jobs failures --bead hides other bead" "33333333" echo "$output"
teardown_api_test

# ── diagnose ────────────────────────────────────────
echo "-- diagnose --"

# diagnose shows bead subject
setup_api_test
output=$(run_dd diagnose aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "diagnose shows bead subject" "Implement auth flow" echo "$output"
teardown_api_test

# diagnose shows job history
setup_api_test
output=$(run_dd diagnose aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "diagnose shows Jobs header" "Jobs (2)" echo "$output"
assert_contains "diagnose shows completed job" "11111111" echo "$output"
assert_contains "diagnose shows failed job" "22222222" echo "$output"
teardown_api_test

# diagnose shows failure error message
setup_api_test
output=$(run_dd diagnose aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "diagnose shows error" "npm test failed" echo "$output"
assert_contains "diagnose shows Latest Failure header" "Latest Failure" echo "$output"
teardown_api_test

# diagnose shows failure analysis
setup_api_test
output=$(run_dd diagnose aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "diagnose shows analysis" "Test assertion failed" echo "$output"
teardown_api_test

# diagnose shows log tail
setup_api_test
output=$(run_dd diagnose aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa 2>&1) || true
assert_contains "diagnose shows log section" "Log (last 30 lines)" echo "$output"
assert_contains "diagnose shows log content" "line1" echo "$output"
teardown_api_test

# diagnose without ID exits 1
assert_exit "diagnose without ID exits 1" 1 "$DEVDASH" diagnose

# ── jobs log --tail ─────────────────────────────────
echo "-- jobs log --tail --"

# jobs log --tail shows only last N lines
setup_api_test
output=$(run_dd jobs log 22222222-2222-2222-2222-222222222222 --tail=5 2>&1) || true
assert_contains "jobs log --tail shows last line" "line30" echo "$output"
assert_contains "jobs log --tail shows line26" "line26" echo "$output"
assert_not_contains "jobs log --tail hides early lines" "line25" echo "$output"
teardown_api_test

# jobs log without --tail shows full log
setup_api_test
output=$(run_dd jobs log 22222222-2222-2222-2222-222222222222 2>&1) || true
assert_contains "jobs log full shows first line" "line1" echo "$output"
assert_contains "jobs log full shows last line" "line30" echo "$output"
teardown_api_test
