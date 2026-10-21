# OASF Server Release Process

This document describes how the OASF server and its Helm chart are released.

## Versioning

- The server follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html), independently of the schema version. A breaking change to the API, the configuration or the image bumps the major version.
- The server does not ship a schema. Each server release states which schema versions it supports in [CHANGELOG.md](./CHANGELOG.md).
- `mix.exs` on `main` holds the next version with a `-dev` suffix, for example `2.1.0-dev`.
- Releases up to `v1.x` were cut from [agntcy/oasf](https://github.com/agntcy/oasf) and bundled a schema. Their tags are kept in this repository as `bundle/v*` and are not released again.

## Releasing the Server

Releases are tagged on `main`; there are no release branches.

1. Open a pull request that sets the version in `mix.exs` (drop the `-dev` suffix) and moves the `Unreleased` entries in `CHANGELOG.md` under the new version.
2. Once it is merged, tag the merge commit with `vX.Y.Z` and push the tag. CI builds, signs and publishes `ghcr.io/agntcy/oasf-server:vX.Y.Z`.
3. Generate release notes on GitHub and publish the release.
4. Open a pull request that bumps `mix.exs` to the next `-dev` version.

## API Version Bumping

The API version in `lib/schema_web/router.ex` only needs to be bumped when the API endpoints themselves change.

## Releasing a New Chart Version

Use tags with the prefix `helm/` followed by the chart version, for example `helm/vX.Y.Z`.
