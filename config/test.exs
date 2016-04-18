use Mix.Config

config :exfile, Exfile,
  secret: "donttellanyone",
  backends: %{
    "store" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/store"),
      hasher: Exfile.Hasher.Random
    },
    "cache" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/cache"),
      hasher: Exfile.Hasher.Random
    },
    "pre" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/pre"),
      hasher: Exfile.Hasher.Random,
      preprocessors: ["reverse"]
    },
    "pre-post" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/pre-post"),
      hasher: Exfile.Hasher.Random,
      preprocessors: ["reverse"],
      postprocessors: [{"truncate", ["5"]}]
    },
    "limited" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/limited"),
      max_size: 100
    },
  },
  allow_uploads_to: ["cache", "limited"]

config :logger, level: :info
