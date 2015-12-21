use Mix.Config

config :exfile, Exfile,
  secret: "donttellanyone",
  backends: %{
    "store" => [Exfile.Backend.FileSystem, %{
      directory: Path.expand("./tmp/store"),
      max_size: nil,
      hasher: Exfile.Hasher.Random
    }],
    "cache" => [Exfile.Backend.FileSystem, %{
      directory: Path.expand("./tmp/cache"),
      max_size: nil,
      hasher: Exfile.Hasher.Random
    }]
  }
