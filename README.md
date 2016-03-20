# Exfile

[![Build Status](https://travis-ci.org/keichan34/exfile.svg?branch=master)](https://travis-ci.org/keichan34/exfile) [![hex.pm](https://img.shields.io/hexpm/v/exfile.svg)](https://hex.pm/packages/exfile) [![hexdocs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](http://hexdocs.pm/exfile/readme.html)

File upload handling in Elixir and Plug. Inspired heavily by [Refile](https://github.com/refile/refile).
If you use Ruby, check Refile out. I like it. A lot. 👍

Requires Elixir `~> 1.2.0`. At this point, it is only tested against the most 
recent version of Elixir.

In very heavy development. Expect things to break. I'll release 1.0 when it's
ready and I have it in a production environment.

## Storage Adapters

Exfile, like Refile, supports pluggable storage adapters. Exfile ships with a
filesystem-backed storage adapter.

* [exfile-memory](https://github.com/keichan34/exfile-memory) -- a memory-backed
	(ETS) storage adapter. This is usually only useful as a cache.
* [exfile-b2](https://github.com/keichan34/exfile-b2) -- storage adapter for
	Backblaze B2.

## File Processors

Exfile supports pluggable file processors / filters. If you're working with
images, `exfile-imagemagick` is recommended.

* [exfile-imagemagick](https://github.com/keichan34/exfile-imagemagick)

## Installation

1. Add exfile to your list of dependencies in `mix.exs`:

	```elixir
	def deps do
	  [{:exfile, "~> 0.2.0"}]
	end
	```

2. Ensure exfile is started before your application:

	```elixir
	def application do
	  [applications: [:exfile]]
	end
	```

3. Mount the Exfile routes in your router.

### Phoenix

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router

  foward "/attachments", Exfile.Router
  ...
```

To use the `exfile_path` and `exfile_url` helpers, include the
`Exfile.Phoenix.Helpers` module where you need it (probably in the `view`
section of your `web/web.ex` file).

Phoenix uses `Plug.Parsers` with a 8 MB limit by default -- this affects Exfile
too. To increase it, find `Plug.Parsers` in `MyApp.Endpoint` and add the `length`
option:

```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  plug Plug.Parsers,
    ...
    length: 25_000_000 # bytes; any value you deem necessary
end
```

### Plug

```elixir
defmodule MyApp.Router do
  use Plug.Router

  forward "/attachments", to: Exfile.Router
  ...
```

### Ecto Integration

The following example will upload a file to the backend configured as "store".
If you want to upload files to an alternate backend, please take a look at
`Exfile.Ecto.File` and `Exfile.Ecto.FileTemplate` for instructions on making
a custom `Ecto.Type` for your needs.

```elixir
defmodule MyApp.User do
  use Ecto.Schema

  schema "users" do
    field :profile_picture, Exfile.Ecto.File
  end
end
```

## Configuration

In `config.exs`:

```elixir
config :exfile, Exfile,
  secret: "secret string to generate the token used to authenticate requests",
  backends: %{
    "store" => configuration for the default persistent store
    "cache" => configuration for an ephemeral store holding temporarily uploaded content
  }
```

See `Exfile.Config` for defaults.
