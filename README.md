# Open Agentic Schema Framework Server

The schema server is an HTTP server that provides a convenient way to browse and
use the OASF schema.

## Local Usage

This section describes how to build and run the OASF Schema server.

### Required Build Tools

The Schema server is written in [Elixir](https://elixir-lang.org) using the
[Phoenix](https://phoenixframework.org/) Web framework.

The Elixir site maintains a great installation page, see
[this](https://elixir-lang.org/install.html) for help.

### Building the Schema Server

Elixir uses the [`mix`](https://hexdocs.pm/mix/Mix.html) build tool, which is
included in the Elixir installation package.

#### Install the Build Tools

```shell
mix local.hex --force && mix local.rebar --force
```

#### Get the Dependencies

Fetch and compile the dependencies:

```shell
mix do deps.get, deps.compile
```

#### Compile the Source Code

```shell
mix compile
```

### Testing Local Schema Changes

You can use `mix test` command to test the changes made to the schema.
For example, to ensure the JSON files are correct or the attributes are defined,
with this command:

```shell
SCHEMA_DIR=../oasf/schema SCHEMA_EXTENSION=test/extensions mix test
```

If everything is correct, then you should not see any errors or warnings.

### Supported Schema Versions

[`schema-versions.json`](./schema-versions.json) lists the schema versions this server
supports, each with the [agntcy/oasf](https://github.com/agntcy/oasf) release tag (`ref`)
its schema is tested from, and marks one as the default. Renovate bumps each `ref` to the
latest patch of its line.

- `task test` runs the test suite against the default version. The schema is downloaded
  into `.schemas/<ref>`; set `SCHEMA_DIR` to test against another schema.
- `task test:smoke SCHEMA=<version>` boots the server image with one supported version and
  checks the main pages and API endpoints, plus the page, JSON schema export and a
  validated sample of every class and object. `task test:smoke:all` runs it for every
  version, and CI runs it as a matrix.
- A nightly workflow runs the test suite against `agntcy/oasf@main`, to catch schema
  changes the server does not handle yet.

### Running the Schema Server

You can use the Elixir's interactive shell,
[IEx](https://hexdocs.pm/iex/IEx.html), to start the schema server use:

```shell
iex -S mix phx.server
```

In the `dev` environment `SCHEMA_DIR` defaults to `../oasf/schema`, a checkout of
[agntcy/oasf](https://github.com/agntcy/oasf) next to this repository, and `SCHEMA_EXTENSION`
defaults to `test/extensions`, which holds the [example extension](https://github.com/agntcy/oasf/tree/main/schema/test/extensions/example).
Set `SCHEMA_EXTENSION=""` to run without extensions, or point it at your own extensions.

Now you can access the Schema server at
[`localhost:8080`](http://localhost:8080).

### Reloading the Schema

You can use the following command in the `iex` shell to force reloading the
schema with extensions:

```elixir
Schema.reload(["<extension folder>", "<extension folder>", ...])
```

Reload the core schema without extensions:

```elixir
Schema.reload()
```

Reload the schema only with the `example` extension (note that the folder is relative
to the `SCHEMA_DIR` folder):

```elixir
Schema.reload(["test/extensions/example"])
```

Reload the schema with all extensions defined in the `extensions` folder (note that
the folder is relative to the `SCHEMA_DIR` folder):

```elixir
Schema.reload(["extensions"])
```

Reload the schema with extensions defined outside the `SCHEMA_DIR` folder (use
an absolute or relative path):

```elixir
Schema.reload(["/home/schema/cloud", "../dev-ext"])
```

### Runtime Configuration

The schema server uses a number of environment variables.

| Variable Name    | Description                                                                               |
| ---------------- | ----------------------------------------------------------------------------------------- |
| HTTP_PORT        | The server HTTP port number, default: `8080`                                              |
| LOG_LEVEL        | Logger level (`debug`, `info`, `warning`, `error`), default: `warning`                    |
| SCHEMA_DIR       | The directory containing the schema, default: `../oasf/schema`, or `/app/schema` in the image |
| SCHEMA_EXTENSION | Comma-separated extension directories, relative to SCHEMA_DIR or absolute; blank for none |
| RELEASE_NODE     | The Erlang node name. Set it if you want to run more than one server on the same computer |

```shell
SCHEMA_DIR=../oasf/schema SCHEMA_EXTENSION=extensions iex -S mix phx.server
```

### Running the Docker Image

The `ghcr.io/agntcy/oasf-server` image does not contain a schema. Mount one at
`/app/schema` (the image's `SCHEMA_DIR`). Without a schema the server prints an
error and exits with a non-zero status:

```text
error: No schema found in SCHEMA_DIR=/app/schema: /app/schema/version.json does not exist. ...
```

To serve a schema from a local checkout of [agntcy/oasf](https://github.com/agntcy/oasf):

```shell
docker run --rm -p 8080:8080 -v $PWD/schema:/app/schema:ro ghcr.io/agntcy/oasf-server:latest
```

Released schemas are also published as `ghcr.io/agntcy/oasf-schema` images, with the
schema under `/schema`. Copy one into a volume and mount that volume in the server:

```shell
docker run --rm -v oasf-schema:/app/schema ghcr.io/agntcy/oasf-schema:v1.1.1 cp -R /schema/. /app/schema
docker run --rm -p 8080:8080 -v oasf-schema:/app/schema:ro ghcr.io/agntcy/oasf-server:latest
```

`task test:image` checks both cases against a locally built image.
