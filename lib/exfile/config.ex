defmodule Exfile.Config do
  @default_config [
    allow_downloads_from: :all,
    allow_uploads_to: ["cache"],
    secret: nil,
    backends: %{
      "store" => [Exfile.Backend.FileSystem, %{
        directory: Path.expand("./priv/tmp/store"),
        max_size: nil,
        hasher: Exfile.Hasher.Random
      }],
      "cache" => [Exfile.Backend.FileSystem, %{
        directory: Path.expand("./priv/tmp/cache"),
        max_size: nil,
        hasher: Exfile.Hasher.Random
      }]
    }
  ]

  Enum.each @default_config, fn {key, _default} ->
    def unquote(key)() do
      Application.get_env(:exfile, Exfile, [])
      |> Dict.get(unquote(key), @default_config[unquote(key)])
    end
  end

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  ## Callbacks

  @doc false
  def init(:ok) do
    send(self, :refresh_backend_config)
    {:ok, %{}}
  end

  def handle_info(:refresh_backend_config, state) do
    exfile_config = Application.get_env(:exfile, Exfile, [])
    backends = Dict.get(exfile_config, :backends)
    backends = if backends do
      instantiate_backends(backends)
    else
      instantiate_backends(@default_config[:backends])
    end
    exfile_config = Dict.put(exfile_config, :backends, backends)
    Application.put_env(:exfile, Exfile, exfile_config)
    {:noreply, state}
  end

  def code_change(_, state, _) do
    send(self, :refresh_backend_config)
    {:ok, state}
  end

  defp instantiate_backends(backends) do
    Enum.map(backends, fn {key, [mod, argv]} ->
      argv = Dict.put(argv, :name, key)
      {key, apply(mod, :init, [argv])}
    end) |> Enum.into(%{})
  end
end
