#!/usr/bin/env bash

set -euo pipefail

API_URL="${API_URL:-http://localhost:8080}"
NGINX_URL="${NGINX_URL:-http://localhost:8088}"
DEVICE_ID="${DEVICE_ID:-11111111-1111-1111-1111-111111111111}"
SUNO_CALLBACK_SECRET="${SUNO_CALLBACK_SECRET:-change-me}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

request() {
  local method="$1"
  local url="$2"
  local body_file="$3"
  shift 3

  curl -sS -X "$method" "$url" \
    -o "$body_file" \
    -w "%{http_code}" \
    "$@"
}

assert_status() {
  local actual="$1"
  local expected="$2"
  local body_file="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "expected HTTP $expected, got $actual"
    cat "$body_file"
    exit 1
  fi
}

assert_contains() {
  local body_file="$1"
  local expected="$2"

  if ! grep -Fq "$expected" "$body_file"; then
    echo "expected body to contain: $expected"
    cat "$body_file"
    exit 1
  fi
}

echo "checking health and readiness"

health_body="$tmpdir/health.txt"
status="$(request GET "$API_URL/health" "$health_body")"
assert_status "$status" "200" "$health_body"
assert_contains "$health_body" "ok"

ready_body="$tmpdir/ready.txt"
status="$(request GET "$API_URL/ready" "$ready_body")"
assert_status "$status" "200" "$ready_body"
assert_contains "$ready_body" "ready"

proxy_health_body="$tmpdir/proxy_health.txt"
status="$(request GET "$NGINX_URL/health" "$proxy_health_body")"
assert_status "$status" "200" "$proxy_health_body"
assert_contains "$proxy_health_body" "ok"

echo "checking job creation"

job_body="$tmpdir/job.json"
status="$(request POST "$API_URL/jobs" "$job_body" \
  -H "Content-Type: application/json" \
  -H "X-Device-Id: $DEVICE_ID" \
  --data '{"prompt":"Calm piano track","instrumental":true,"model":"V4_5ALL"}')"
assert_status "$status" "201" "$job_body"
assert_contains "$job_body" '"status":"queued"'
assert_contains "$job_body" '"prompt":"Calm piano track"'

echo "checking validation path"

bad_job_body="$tmpdir/bad_job.txt"
status="$(request POST "$API_URL/jobs" "$bad_job_body" \
  -H "Content-Type: application/json" \
  --data '{"prompt":"test"}')"
assert_status "$status" "400" "$bad_job_body"
assert_contains "$bad_job_body" "X-Device-Id is required"

echo "checking callback endpoint"

callback_body="$tmpdir/callback.json"
status="$(request POST "$API_URL/suno/callback" "$callback_body" \
  -H "Content-Type: application/json" \
  -H "X-Suno-Callback-Secret: $SUNO_CALLBACK_SECRET" \
  --data '{"taskId":"task-1","callbackType":"text"}')"
assert_status "$status" "200" "$callback_body"
assert_contains "$callback_body" '"status":"received"'

echo "smoke checks passed"
