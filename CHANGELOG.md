# Changelog

All notable changes to the OASF server are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the server follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) from `v2.0.0` on. See [RELEASE.md](./RELEASE.md).

Releases up to `v1.x` shipped the server bundled with a schema from [agntcy/oasf](https://github.com/agntcy/oasf), and their history is in that repository's [CHANGELOG.md](https://github.com/agntcy/oasf/blob/main/CHANGELOG.md). Those tags are kept here as `bundle/v*`.

## Unreleased

### Added

- `URL_SCHEME` sets the scheme of the server's public URL, for example `https` behind a TLS-terminating ingress. `URL_PORT` then defaults to `443` ([#10](https://github.com/agntcy/oasf-server/pull/10)).

### Changed

- The chart's `image.tag` names the server release it deploys (`v2.0.0`) instead of being empty, so upgrading the server means changing that one value ([#11](https://github.com/agntcy/oasf-server/pull/11)).

### Fixed

- Generated `record` samples no longer repeat a locator type, which the validator rejects ([#8](https://github.com/agntcy/oasf-server/pull/8)).
- The Validate button on object and class pages opens the Swagger UI (`/doc`, or `/<version>/doc` on a versioned page) instead of the removed `/doc/index.html` ([#9](https://github.com/agntcy/oasf-server/pull/9)).
- `/api/version` and `/api/versions` report the public URL without its scheme's default port, and no longer with port `8000` when the image listens on `8080` ([#10](https://github.com/agntcy/oasf-server/pull/10)).

## [v2.0.0](https://github.com/agntcy/oasf-server/releases/tag/v2.0.0) - 2026-10-22

Supported schema versions: `1.1.0` (default), `1.0.0` and `0.8.0`, from the `ghcr.io/agntcy/oasf-schema` images of the same tags. See [schema-versions.json](./schema-versions.json).

### Changed

- **BREAKING:** the server image no longer contains a schema. Mount one at `SCHEMA_DIR` (`/app/schema` in the image), from a host directory or an `oasf-schema` image.
- **BREAKING:** the server refuses to start, with a clear error and a non-zero exit status, when `SCHEMA_DIR` has no `version.json`.
- The server is versioned independently of the schema, starting at `2.0.0`.
- **BREAKING:** Helm chart v2. `image.versions` is replaced by `schema.versions`: one server image (`image.tag`, defaulting to the chart's `appVersion`) serves every version, each mounted from the `oasf-schema` image tagged with its schema version (or `tag`), optionally pinned by digest. `schema.mount` picks an init container (default) or an image volume (Kubernetes 1.35+). Resource names and ingress paths are unchanged. Rendering fails without versions, on duplicates or with more than one default.
- The chart runs the server as non-root with a read-only root filesystem by default.
- The chart is published as `oci://ghcr.io/agntcy/oasf-server/helm-charts/oasf`.

### Fixed

- The chart's HPA ignored `targetCPUUtilizationPercentage` and `targetMemoryUtilizationPercentage` because of a typo in the template.
- Cap the BEAM port table at 65536 with `+Q`, so the server's memory no longer grows with the runtime's open-file limit.
- Image cleanup could delete release, `main` and `latest` images, or the platform manifests behind them.
