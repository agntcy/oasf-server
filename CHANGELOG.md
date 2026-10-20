# Changelog

All notable changes to the OASF server are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the server follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) from `v2.0.0` on. See [RELEASE.md](./RELEASE.md).

Releases up to `v1.x` shipped the server bundled with a schema from [agntcy/oasf](https://github.com/agntcy/oasf), and their history is in that repository's [CHANGELOG.md](https://github.com/agntcy/oasf/blob/main/CHANGELOG.md). Those tags are kept here as `bundle/v*`.

## Unreleased

### Changed

- **BREAKING:** the server image no longer contains a schema. Mount one at `SCHEMA_DIR` (`/app/schema` in the image), from a host directory or an `oasf-schema` image.
- **BREAKING:** the server refuses to start, with a clear error and a non-zero exit status, when `SCHEMA_DIR` has no `version.json`.
- The server is versioned independently of the schema, starting at `2.0.0`.

### Fixed

- Cap the BEAM port table at 65536 with `+Q`, so the server's memory no longer grows with the runtime's open-file limit.
