#!/usr/bin/env bash
# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0
#
# Smoke-test a running OASF server: the main pages and API endpoints, and for every
# skill, domain, module and object its page, JSON schema export and a generated sample,
# which must pass validation.
#
# Usage: scripts/smoke-test.sh <base url> [expected schema version]

set -euo pipefail

base=${1:?usage: $0 <base url> [expected schema version]}
expected=${2:-}
failures=0
requests=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

get() {
  local path=$1 status
  requests=$((requests + 1))
  status=$(curl --silent --output /dev/null --write-out '%{http_code}' "$base$path") || status=000
  [ "$status" = 200 ] || fail "GET $path returned $status"
}

validate() {
  local sample_path=$1 validate_path=$2 sample result
  requests=$((requests + 2))
  if ! sample=$(curl --silent --fail "$base$sample_path"); then
    fail "GET $sample_path failed"
    return
  fi
  if ! result=$(curl --silent --fail -H 'content-type: application/json' --data "$sample" "$base$validate_path"); then
    fail "POST $validate_path failed for a sample from $sample_path"
    return
  fi
  if [ "$(jq -r '.error_count' <<< "$result")" != 0 ]; then
    fail "POST $validate_path rejected a sample from $sample_path: $(jq -c '.errors' <<< "$result")"
  fi
}

curl --silent --fail --retry 30 --retry-delay 2 --retry-all-errors --output /dev/null "$base/api/version"

version=$(curl --silent --fail "$base/api/version" | jq -r '.schema_version')
echo "Smoke-testing $base (schema $version)"
if [ -n "$expected" ] && [ "$version" != "$expected" ]; then
  fail "expected schema version $expected, got $version"
fi

for path in / /skills /domains /modules /objects /profiles /dictionary /data_types \
  /skill_categories /domain_categories /module_categories /doc \
  /api/version /api/versions /api/profiles /api/extensions /api/dictionary /api/data_types \
  /api/schema /api/skill_categories /api/domain_categories /api/module_categories \
  /api/skills /api/domains /api/modules /api/objects; do
  get "$path"
done

# Names in a catalog endpoint. Assigned before looping over them, because a failed
# command substitution in a for list does not trip set -e.
names() {
  curl --silent --fail "$base$1" | jq -r 'keys[]'
}

profiles=$(names /api/profiles) || fail "could not list /api/profiles"
for profile in $profiles; do
  get "/api/profiles/$profile"
done

for kind in skills domains modules objects; do
  singular=${kind%s}
  list=$(names "/api/$kind") || { fail "could not list /api/$kind"; continue; }
  [ -n "$list" ] || fail "/api/$kind is empty"
  for name in $list; do
    get "/$kind/$name"
    get "/schema/$kind/$name"
    if [ "$kind" = objects ]; then
      validate "/sample/$kind/$name" "/api/validate/object/$name"
    else
      validate "/sample/$kind/$name" "/api/validate/$singular"
    fi
  done
done

echo "$requests requests, $failures failures"
[ "$failures" -eq 0 ]
