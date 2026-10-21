#!/usr/bin/env bash
# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0
#
# Check a chart deployment that serves every version in schema-versions.json,
# plus one version whose schema image does not exist:
# - every version and the default routes respond with the right schema version,
# - every instance reports the same server version,
# - each version passes the smoke test through the ingress,
# - the version with the missing schema image stays unready,
# - each server's memory stays bounded.
#
# Usage: scripts/e2e-check.sh <base url> <schema-versions.json> <missing schema version>

set -euo pipefail

base=${1:?usage: $0 <base url> <schema-versions.json> <missing schema version>}
versions_file=${2:?}
missing=${3:?}
kubectl=${KUBECTL:-kubectl}
release=${RELEASE_NAME:-oasf}
max_rss_kb=${MAX_RSS_KB:-262144}
script_dir=$(cd "$(dirname "$0")" && pwd)
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

default=$(jq -er '.versions[] | select(.default) | .schema' "$versions_file")
schemas=$(jq -r '.versions[].schema' "$versions_file")

echo "== Versions and default routes"
server_versions=""
for schema in $schemas; do
  if ! body=$(curl --silent --fail --retry 10 --retry-delay 3 --retry-all-errors "$base/api/$schema/version"); then
    fail "GET /api/$schema/version failed"
    continue
  fi
  got=$(jq -r .schema_version <<< "$body")
  [ "$got" = "$schema" ] || fail "/api/$schema/version reports schema $got"
  server_versions+="$(jq -r .server_version <<< "$body")"$'\n'
  echo "$schema: $body"
done

body=$(curl --silent --fail "$base/api/version") || fail "GET /api/version failed"
[ "$(jq -r .schema_version <<< "${body:-null}")" = "$default" ] || fail "/api/version should serve the default schema $default, got: ${body:-}"
for path in / /objects /api/objects /schema/objects/locator /sample/objects/locator; do
  status=$(curl --silent --output /dev/null --write-out '%{http_code}' "$base$path")
  [ "$status" = 200 ] || fail "GET $path (default version) returned $status"
done

extensions=$(curl --silent --fail "$base/api/extensions") || fail "GET /api/extensions failed"
[ "${extensions:-}" = "{}" ] || fail "expected no extensions to be loaded, got: ${extensions:-}"

listed=$(curl --silent --fail "$base/api/versions" | jq -r '[.versions[].schema_version] | sort | join(" ")')
expected=$( (echo "$schemas"; echo "$missing") | sort -V | paste -sd' ' -)
[ "$(tr ' ' '\n' <<< "$listed" | sort -V | paste -sd' ' -)" = "$expected" ] || fail "/api/versions lists $listed, expected $expected"

echo "== Server versions"
unique=$(sort -u <<< "$server_versions" | sed '/^$/d')
if [ "$(wc -l <<< "$unique")" -ne 1 ]; then
  fail "instances report different server versions: $(paste -sd' ' - <<< "$unique")"
else
  echo "all instances report $unique"
fi

echo "== Smoke tests through the ingress"
for schema in $schemas; do
  "$script_dir/smoke-test.sh" "$base/$schema" "$schema" || fail "smoke test failed for $schema"
done

echo "== Version with a missing schema image"
deployment="$release-$(tr . - <<< "$missing")"
ready=$($kubectl get deployment "$deployment" -o jsonpath='{.status.readyReplicas}')
[ -z "$ready" ] || [ "$ready" = 0 ] || fail "$deployment has $ready ready replicas, expected none"
reason=$($kubectl get pods -l "schema-version=$missing" -o jsonpath='{.items[0].status.initContainerStatuses[0].state.waiting.reason}{.items[0].status.containerStatuses[0].state.waiting.reason}')
case "$reason" in
  *ErrImagePull*|*ImagePullBackOff*|*PodInitializing*|*ContainerCreating*) echo "$deployment is unready: $reason" ;;
  *) fail "$deployment should be waiting for its schema image, got: ${reason:-no waiting reason}" ;;
esac
status=$(curl --silent --output /dev/null --write-out '%{http_code}' "$base/api/$missing/version")
[ "$status" != 200 ] || fail "/api/$missing/version responded although its schema image is missing"

echo "== Memory"
for schema in $schemas; do
  pod=$($kubectl get pods -l "schema-version=$schema" -o jsonpath='{.items[0].metadata.name}')
  rss=$($kubectl exec "$pod" -- sh -c 'grep VmRSS /proc/$(pidof beam.smp)/status' | awk '{print $2}')
  echo "$schema: $((rss / 1024)) MB"
  [ "$rss" -le "$max_rss_kb" ] || fail "$pod uses $((rss / 1024)) MB, more than $((max_rss_kb / 1024)) MB"
done

echo "$failures failures"
[ "$failures" -eq 0 ]
