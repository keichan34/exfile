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
    }],
    "pre" => [Exfile.Backend.FileSystem, %{
      directory: Path.expand("./tmp/pre"),
      max_size: nil,
      hasher: Exfile.Hasher.Random,
      preprocessors: ["reverse"]
    }],
    "pre-post" => [Exfile.Backend.FileSystem, %{
      directory: Path.expand("./tmp/pre-post"),
      max_size: nil,
      hasher: Exfile.Hasher.Random,
      preprocessors: ["reverse"],
      postprocessors: [{"truncate", ["5"]}]
    }]
  }

config :logger, level: :info
