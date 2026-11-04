#!/usr/bin/env bash
# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0
#
# Print the release notes for a tag: its section of CHANGELOG.md, without the
# heading. A section's heading names every tag it is released under, for example
#
#   ## [v2.0.0](...) and [helm/v2.0.0](...) - 2026-10-22
#
# The notes of a chart tag (helm/v*) start with the server version the chart
# deploys by default. Relative links point at the tagged files. Fails if the
# changelog has no section, or an empty one, for the tag.
#
# Usage: scripts/release-notes.sh <tag> [changelog] [chart directory] [schema versions]

set -euo pipefail

tag=${1:?usage: $0 <tag> [changelog] [chart directory] [schema versions]}
changelog=${2:-CHANGELOG.md}
chart=${3:-install/charts/oasf}
versions=${4:-schema-versions.json}

# The section runs from the heading naming [<tag>] to the next "## " heading.
# Leading blank lines are dropped here, trailing ones by the substitution.
section=$(awk -v tag="[$tag]" '
  /^## / { if (found) exit; found = index($0, tag) > 0; next }
  found
' "$changelog" | sed -e '/./,$!d')

if [[ -z "${section//[[:space:]]/}" ]]; then
  echo "error: $changelog has no section for $tag, or an empty one; add one under a heading naming [$tag]" >&2
  exit 1
fi

case "$tag" in
  helm/*)
    version=${tag#helm/}
    app_version=$(yq -er .appVersion "$chart/Chart.yaml")
    # The chart serves no schema version by default, so the example lists one.
    schema=$(jq -er '.versions[] | select(.default) | .schema' "$versions")
    echo "This chart deploys \`ghcr.io/agntcy/oasf-server:${app_version}\` by default."
    echo "List the schema versions to serve under \`schema.versions\` in a values file:"
    echo
    echo '```yaml'
    echo 'schema:'
    echo '  versions:'
    echo "    - schema: ${schema}"
    echo '      default: true'
    echo '```'
    echo
    echo '```shell'
    echo "helm install oasf oci://ghcr.io/agntcy/oasf-server/helm-charts/oasf --version ${version} -f values.yaml"
    echo '```'
    ;;
  *)
    echo "Image: \`ghcr.io/agntcy/oasf-server:${tag}\`"
    ;;
esac
echo
# Relative links resolve against the repository, not the releases page, so
# point them at the tagged files.
echo "$section" | sed -e "s|](\./|](https://github.com/agntcy/oasf-server/blob/${tag}/|g"
