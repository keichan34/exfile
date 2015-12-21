# Exfile

[![Build Status](https://travis-ci.org/keichan34/exfile.svg?branch=master)](https://travis-ci.org/keichan34/exfile)

File upload handling in Elixir and Plug. Inspired heavily by [Refile](https://github.com/refile/refile).
If you use Ruby, check Refile out. I like it. A lot. 👍

## Storage Adapters

Exfile, like Refile, supports pluggable storage adapters. Exfile ships with a
filesystem-backed storage adapter.

* [exfile-memory](https://github.com/keichan34/exfile-memory) -- a memory-backed
  (ETS) storage adapter. This is usually only useful as a cache.

## File Processors

Exfile supports pluggable file processors / filters. If you're working with
images, `exfile-imagemagick` is recommended.

* [exfile-imagemagick](https://github.com/keichan34/exfile-imagemagick)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exfile to your list of dependencies in `mix.exs`:

        def deps do
          [{:exfile, "~> 0.0.1"}]
        end

  2. Ensure exfile is started before your application:

        def application do
          [applications: [:exfile]]
        end

  3. Mount the Exfile routes in your router.

### Phoenix

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router

  foward "/attachments", Exfile.Router
  ...
```

### Plug

```elixir
defmodule MyApp.Router do
  use Plug.Router

  forward "/attachments", to: Exfile.Router
  ...
```

## Configuration

In `config.exs`:

```elixir
config :exfile, Exfile,
  secret: "secret string to generate the token used to authenticate requests",
  backends: %{
    "store" => configuration for a persistent store,
    "cache" => configuration for an ephemeral cache
  }
```

See `lib/exfile/config.ex` for defaults.
