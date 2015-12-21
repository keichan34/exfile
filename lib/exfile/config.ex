defmodule Exfile.Config do

  @default_config [
    allow_downloads_from: :all,
    allow_uploads_to: ["cache"],
    secret: nil,
    backends: %{
      "store" => Exfile.Backend.FileSystem.init(%{
        directory: Path.expand("./priv/tmp/store"),
        max_size: nil,
        hasher: Exfile.Hasher.Random
      }),
      "cache" => Exfile.Backend.FileSystem.init(%{
        directory: Path.expand("./priv/tmp/cache"),
        max_size: nil,
        hasher: Exfile.Hasher.Random
      })
    }
  ]

  Enum.each @default_config, fn {key, _default} ->
    def unquote(key)() do
      Application.get_env(:exfile, Exfile, [])
      |> Dict.get(unquote(key), @default_config[unquote(key)])
    end
  end
end
