#!/usr/bin/env bash
# Exercise credentialed CLI requests through the curl mock. The mock records
# destinations and redirect controls, never the test credentials themselves.

echo "-- API origin and redirect security --"

setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
echo '{"project_id":"95ca3de0-7e4f-4f9e-9b17-36f5609cfa11","api_url":"https://attacker.example"}' > "${_MOCK_WORKDIR}/.devdash"
unset DD_API_URL
assert_exit "malicious HTTPS repo API ignored" 0 run_dd list
assert_contains "default API origin used" "https://devdash-prime.up.railway.app/api/beads" cat "${MOCK_CURL_LOG}.urls"
assert_not_contains "attacker origin never contacted" "attacker.example" cat "${MOCK_CURL_LOG}.urls"
assert_contains "project ID still read from repo" "projectId=95ca3de0-7e4f-4f9e-9b17-36f5609cfa11" cat "${MOCK_CURL_LOG}.urls"
assert_not_contains "no foreign redirect credential forwarding" "foreign-origin credential forwarding possible" cat "${MOCK_CURL_LOG}.security"
assert_contains "curl config disabled" "config=disabled auth=present" cat "${MOCK_CURL_LOG}.security"
assert_contains "redirect following disabled" "redirects=0 config=disabled auth=present" cat "${MOCK_CURL_LOG}.security"
teardown_api_test

setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
echo '{"project_id":"95ca3de0-7e4f-4f9e-9b17-36f5609cfa11","api_url":"http://attacker.example"}' > "${_MOCK_WORKDIR}/.devdash"
unset DD_API_URL
assert_exit "malicious HTTP repo API ignored" 0 run_dd list
assert_not_contains "HTTP attacker origin never contacted" "attacker.example" cat "${MOCK_CURL_LOG}.urls"
teardown_api_test

setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
echo '{"project_id":"95ca3de0-7e4f-4f9e-9b17-36f5609cfa11","api_url":"https://attacker.example"}' > "${_MOCK_WORKDIR}/.devdash"
export DD_API_URL="https://trusted.example:8443"
assert_exit "explicit custom HTTPS origin works" 0 run_dd list
assert_contains "explicit origin takes precedence" "https://trusted.example:8443/api/beads" cat "${MOCK_CURL_LOG}.urls"
assert_not_contains "repo origin cannot override explicit origin" "attacker.example" cat "${MOCK_CURL_LOG}.urls"
assert_not_contains "custom origin redirect stays local" "foreign-origin credential forwarding possible" cat "${MOCK_CURL_LOG}.security"
teardown_api_test

setup_api_test
export DD_API_URL="http://attacker.example"
assert_exit "non-loopback HTTP rejected before curl" 3 run_dd list
assert_exit "doctor rejects non-loopback HTTP" 3 run_dd doctor
if [ -s "${MOCK_CURL_LOG}.urls" ]; then
  fail "non-loopback HTTP made no request"
else
  pass "non-loopback HTTP made no request"
fi
teardown_api_test

setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
assert_exit "explicit loopback HTTP works" 0 run_dd list
assert_contains "loopback origin used" "http://localhost:9999/api/beads" cat "${MOCK_CURL_LOG}.urls"
assert_not_contains "loopback redirect cannot forward token" "foreign-origin credential forwarding possible" cat "${MOCK_CURL_LOG}.security"
teardown_api_test

# Other paths that send credentials must use the same curl controls.
setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
assert_exit "token login verifies on trusted origin" 0 run_dd login --token=dd_testtoken123
assert_contains "token login prevents redirects" "GET http://localhost:9999/api/projects redirects=0 config=disabled auth=present" cat "${MOCK_CURL_LOG}.security"
teardown_api_test

setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
mkdir -p "${_MOCK_TMPDIR}/doctor-fixtures"
cp "${TEST_DIR}/fixtures/GET_projects.json" "${_MOCK_TMPDIR}/doctor-fixtures/GET_projects.json"
printf '{}\n' > "${_MOCK_TMPDIR}/doctor-fixtures/GET_health.json"
export MOCK_CURL_FIXTURE_DIR="${_MOCK_TMPDIR}/doctor-fixtures"
assert_exit "doctor checks trusted API" 0 run_dd doctor
assert_contains "doctor auth request prevents redirects" "GET http://localhost:9999/api/projects redirects=0 config=disabled auth=present" cat "${MOCK_CURL_LOG}.security"
teardown_api_test

setup_api_test
export MOCK_CURL_REDIRECT="https://attacker.example/collect"
export ADMIN_SECRET="test-only-admin-secret"
run_dd admin reset-user test-user --confirm >/dev/null 2>&1 || true
assert_contains "admin secret request prevents redirects" "POST http://localhost:9999/api/admin/reset-user/test-user redirects=0 config=disabled auth=present" cat "${MOCK_CURL_LOG}.security"
assert_not_contains "no credentialed path can follow foreign redirect" "foreign-origin credential forwarding possible" cat "${MOCK_CURL_LOG}.security"
unset ADMIN_SECRET
teardown_api_test
