# Exfile

[![Build Status](https://travis-ci.org/keichan34/exfile.svg?branch=master)](https://travis-ci.org/keichan34/exfile) [![hex.pm](https://img.shields.io/hexpm/v/exfile.svg)](https://hex.pm/packages/exfile) [![hexdocs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](http://hexdocs.pm/exfile/readme.html)

File upload persistence and processing for Phoenix / Plug, with a focus on
flexibility and extendability.

Inspired heavily by  [Refile](https://github.com/refile/refile). If you use
Ruby, check Refile out. I like it. 👍

Requires Elixir `~> 1.2.0`. At this point, it is only tested against the most
recent version of Elixir.

Exfile is used in a production environment at this point, but it still may go
through some breaking changes. Exfile aims to adheres to
[semver v2.0](http://semver.org/spec/v2.0.0.html).

## Storage Adapters

Exfile supports storage backend adapters. A local filesystem based
adapter is included (`Exfile.Backend.FileSystem`) as an example.

* [exfile-b2](https://github.com/keichan34/exfile-b2) -- storage adapter for
	the [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) cloud
	storage service.

## File Processors

Exfile also supports file processors / filters. If you're working with
images, `exfile-imagemagick` is recommended.

* [exfile-imagemagick](https://github.com/keichan34/exfile-imagemagick) -- uses
	ImageMagick to resize, crop, and transform images.
* [exfile-encryption](https://github.com/keichan34/exfile-encryption) -- encrypts
	files before uploading them and decrypts them after downloading them from the
	backend.

## Usage Overview

Exfile applies transforms on the fly; it only stores the original file in the
storage backend. It is expected to be behind a caching HTTP proxy and/or a
caching CDN for performance. Because dimensions and processors are determined
by the path, it is authenticated with a HMAC to make sure it is not tampered
with.

The Phoenix integration comes with two helper functions, `exfile_url` and
`exfile_path`.

For example, the following code will return a path to the `user`'s `profile_picture`
that is converted to JPEG (if not already in JPEG format) and limited to 1024 × 1024.

```elixir
exfile_url(@conn, @user.profile_picture, format: "jpg", processor: "limit", processor_args: [1024, 1024])
```

For more information about what processors are available for images, check out
[exfile-imagemagick](https://github.com/keichan34/exfile-imagemagick).

## Installation

1. Add exfile to your list of dependencies in `mix.exs`:

	```elixir
	def deps do
	  [{:exfile, "~> 0.3.2"}]
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

[There is a sample Phoenix application with Exfile integrated you can check out.](https://github.com/keichan34/phoenix_exfile_test_app)

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

```elixir
defmodule MyApp.Repo.Migrations.AddProfilePictureToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_picture, :string
    end
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
