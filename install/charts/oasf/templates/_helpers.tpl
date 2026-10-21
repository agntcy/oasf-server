{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Regex for a schema semantic version path segment (e.g. 1.2.3 or 1.2.3-beta.1).
*/}}
{{- define "chart.ingress.semverSegmentRegex" -}}
[\d]+\.[\d]+\.[\d]+(?:-[\w.-]+)?
{{- end }}

{{/*
Default API-like ingress path that excludes versioned prefixes.
Example: /api(?!/<semver>(?:/|$))(/|$)(.*)
Usage: include with dict {"root": $, "prefix": "api"}
*/}}
{{- define "chart.ingress.defaultPrefixedPathRegex" -}}
{{- $root := .root -}}
{{- $prefix := .prefix -}}
/{{ $prefix }}(?!/{{ include "chart.ingress.semverSegmentRegex" $root | trim }}(?:/|$))(/|$)(.*)
{{- end }}

{{/*
Default root ingress path that excludes reserved prefixes and versioned prefixes.
*/}}
{{- define "chart.ingress.defaultRootPathRegex" -}}
{{- $root := . -}}
/(?!api(?:/|$)|schema(?:/|$)|export(?:/|$)|sample(?:/|$)|{{ include "chart.ingress.semverSegmentRegex" $root | trim }}(?:/|$))(.*)
{{- end }}

{{/*
Build ingress annotations for rewrite-based ingresses.
Modes:
- community: ingress-nginx annotations only
- f5: F5 NGINX Ingress Controller annotations only
- both: emit both annotation families
User-provided ingress.annotations override chart defaults.
*/}}
{{- define "chart.ingress.annotations.rewrite" -}}
{{- $root := .root -}}
{{- $target := .target -}}
{{- $mode := default "both" $root.Values.ingress.annotationMode -}}
{{- $defaults := dict -}}
{{- if or (eq $mode "community") (eq $mode "both") -}}
{{- $_ := set $defaults "nginx.ingress.kubernetes.io/rewrite-target" $target -}}
{{- $_ := set $defaults "nginx.ingress.kubernetes.io/use-regex" "true" -}}
{{- end -}}
{{- if or (eq $mode "f5") (eq $mode "both") -}}
{{- $_ := set $defaults "nginx.org/path-regex" "case_sensitive" -}}
{{- $_ := set $defaults "nginx.org/rewrite-target" $target -}}
{{- end -}}
{{- toYaml (mergeOverwrite (dict) $defaults ($root.Values.ingress.annotations | default dict)) -}}
{{- end }}

{{/*
Build ingress annotations for doc ingress.
Only ingress-nginx needs an explicit use-regex=false default.
User-provided ingress.annotations override chart defaults.
*/}}
{{- define "chart.ingress.annotations.doc" -}}
{{- $root := . -}}
{{- $mode := default "both" $root.Values.ingress.annotationMode -}}
{{- $defaults := dict -}}
{{- if or (eq $mode "community") (eq $mode "both") -}}
{{- $_ := set $defaults "nginx.ingress.kubernetes.io/use-regex" "false" -}}
{{- end -}}
{{- toYaml (mergeOverwrite (dict) $defaults ($root.Values.ingress.annotations | default dict)) -}}
{{- end }}

{{/*
Validate schema.versions and return the default schema version. Fails rendering
when there are no versions, a version is duplicated or has no schema source, or
more than one version is marked as the default. Without an explicit default, the
first version is the default.
*/}}
{{- define "chart.schema.default" -}}
{{- $versions := .Values.schema.versions | default list -}}
{{- if not $versions -}}
{{- fail "schema.versions must list at least one schema version" -}}
{{- end -}}
{{- $seen := dict -}}
{{- $defaults := list -}}
{{- range $versions -}}
{{- if not .schema -}}
{{- fail "every entry in schema.versions needs a schema version" -}}
{{- end -}}
{{- $schema := toString .schema -}}
{{- if hasKey $seen $schema -}}
{{- fail (printf "schema.versions lists %s more than once" $schema) -}}
{{- end -}}
{{- $_ := set $seen $schema true -}}
{{- if and .tag .hostPath -}}
{{- fail (printf "schema.versions entry %s sets both a tag (schema image tag) and a hostPath" $schema) -}}
{{- end -}}
{{- if .default -}}
{{- $defaults = append $defaults $schema -}}
{{- end -}}
{{- end -}}
{{- if gt (len $defaults) 1 -}}
{{- fail (printf "only one schema.versions entry can be the default, got %s" (join ", " $defaults)) -}}
{{- end -}}
{{- if $defaults -}}
{{- first $defaults -}}
{{- else -}}
{{- (first $versions).schema | toString -}}
{{- end -}}
{{- end }}

{{/*
Server image for one schema version: the version's server.tag, else image.tag,
else the chart's appVersion.
Usage: include with dict {"root": $, "version": $version}
*/}}
{{- define "chart.server.image" -}}
{{- $root := .root -}}
{{- $server := .version.server | default dict -}}
{{- $tag := include "chart.server.tag" . -}}
{{- $digest := ternary ($server.digest | default "") ($root.Values.image.digest | default "") (hasKey $server "tag") -}}
{{- if $digest -}}
{{- printf "%s:%s@%s" $root.Values.image.repository $tag $digest -}}
{{- else -}}
{{- printf "%s:%s" $root.Values.image.repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Server version reported for one schema version: its server image tag.
Usage: include with dict {"root": $, "version": $version}
*/}}
{{- define "chart.server.tag" -}}
{{- $server := .version.server | default dict -}}
{{- $server.tag | default .root.Values.image.tag | default .root.Chart.AppVersion -}}
{{- end }}

{{/*
Schema image for one schema version: tagged with the schema version unless the
version sets a tag, and pinned by digest when one is given.
Usage: include with dict {"root": $, "version": $version}
*/}}
{{- define "chart.schema.image" -}}
{{- $repository := .version.repository | default .root.Values.schema.image.repository -}}
{{- $tag := .version.tag | default (toString .version.schema) -}}
{{- if .version.digest -}}
{{- printf "%s:%s@%s" $repository $tag .version.digest -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Name of the resources for one schema version, e.g. oasf-1-1-0.
Usage: include with dict {"root": $, "version": $version}
*/}}
{{- define "chart.version.fullname" -}}
{{- printf "%s-%s" (include "chart.fullname" .root) (toString .version.schema | replace "." "-") | trunc 63 | trimSuffix "-" -}}
{{- end }}
