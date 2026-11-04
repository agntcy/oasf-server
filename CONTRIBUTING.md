# OASF Server Contribution Guide

Thanks for your interest in contributing to the Open Agentic Schema Framework
(OASF) server!
Here are a few general guidelines on contributing and reporting bugs that we ask
you to review.
Following these guidelines helps to communicate that you respect the time of the
contributors managing and developing this open source project.
In return, they should reciprocate that respect in addressing your issue,
assessing changes, and helping you finalize your pull requests.
In that spirit of mutual respect, we endeavor to review incoming issues and pull
requests within 10 days, and will close any lingering issues or pull requests
after 60 days of inactivity.

Please note that all of your interactions in the project are subject to our
[Code of Conduct](./CODE_OF_CONDUCT.md).
This includes creation of issues or pull requests, commenting on issues or pull
requests, and extends to all interactions in any real-time space for example,
Slack, Discord, and others.

This repository holds the OASF server, its API and its Helm chart.
The schema itself lives in [agntcy/oasf](https://github.com/agntcy/oasf): to
add or change classes, objects, attributes or extensions, follow its
[contribution guide](https://github.com/agntcy/oasf/blob/main/CONTRIBUTING.md).

## Developing the Server

See the [README](./README.md) to build and run the server, to load a local
schema, and to deploy the chart to a local Kind cluster.

Before sending a pull request, run:

```shell
task fmt
task lint
task test
```

`task test` runs the server test suite against the default supported schema
version, with and without the example extension, and the chart unit tests.
CI also boots the server image against every version in
[`schema-versions.json`](./schema-versions.json), so a change that breaks any
supported schema version fails the pull request.

## Reporting Issues

Before reporting a new issue, please ensure that the issue was not already
reported or fixed by searching through our
[issues list](https://github.com/agntcy/oasf-server/issues).
Report problems with the schema content in
[agntcy/oasf](https://github.com/agntcy/oasf/issues) instead.

When creating a new issue, please be sure to include a **title and clear
description**, as much relevant information as possible, and, if possible, a
test case.

**If you discover a security bug, please do not report it through GitHub.
Instead, please see security procedures in [SECURITY.md](./SECURITY.md).**

## Sending Pull Requests

Before sending a new pull request, take a look at existing pull requests and
issues to see if the proposed change or fix has been discussed in the past, or
if the change was already implemented but not yet released.

- Include tests for any affected behavior.
- Add an entry for user-visible changes under `Unreleased` in
  [CHANGELOG.md](./CHANGELOG.md).
- Use a [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  title with one of the scopes `server`, `helm`, `ci`, `api` or `deps`, for
  example `fix(server): resolve validation issue`.

The server follows semantic versioning, so we may reserve breaking changes until
the next major version release.
See [RELEASE.md](./RELEASE.md) for how releases are made.

## Developer’s Certificate of Origin

To improve tracking of who did what, we have introduced a “sign-off” procedure.
The sign-off is a line at the end of the explanation for the commit, which
certifies that you wrote it or otherwise have the right to pass it on as open
source work.
We use the Developer Certificate of Origin (see
https://developercertificate.org/) for our sign-off procedure.
You must include a sign-off in the commit message of your pull request for it to
be accepted.
The format for a sign-off is:

```text
Signed-off-by: Random J Developer <random@developer.example.org>
```

You can use the -s when you do a git commit to simplify including a properly
formatted sign-off in your commits.
If you need to add your sign-off to a commit you have already made, you will
need to amend:

```sh
git commit --amend --signoff
```

## Other Ways to Contribute

We welcome anyone that wants to contribute to OASF to triage and reply to open
issues to help troubleshoot and fix existing bugs.
Here is what you can do:

- Help ensure that existing issues follows the recommendations from the
  _[Reporting Issues](#reporting-issues)_ section, providing feedback to the
  issue's author on what might be missing.
- Review and update the existing content of our
  [docs](https://docs.agntcy.org/oasf/oasf-server/) with up-to-date
  instructions and code samples.
- Review existing pull requests, and testing patches against real existing
  applications that use the OASF server.
- Write a test, or add a missing test case to an existing test.

Thanks again for your interest on contributing to `OASF`!
