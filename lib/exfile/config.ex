defmodule Exfile.Config do
  @default_backends %{
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

  @moduledoc """
  A simple server responsible for Exfile configuration.

  The default configuration:

  ```
  %{
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
  ```
  """

  @default_config [
    allow_downloads_from: :all,
    allow_uploads_to: ["cache"],
    secret: nil
  ]

  Enum.each @default_config, fn {key, _default} ->
    @doc """
    Get "#{key}". Defaults to #{inspect @default_config[key]}
    """
    def unquote(key)() do
      Application.get_env(:exfile, Exfile, [])
      |> Dict.get(unquote(key), @default_config[unquote(key)])
    end
  end

  use GenServer

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc """
  Get the initialized backend for "name"
  """
  def get_backend(name) do
    GenServer.call(__MODULE__, {:get_backend, name})
  end

  @doc """
  Re-initialize all registered backends
  """
  def refresh_backend_config() do
    GenServer.call(__MODULE__, :refresh_backend_config)
  end

  ## Callbacks

  @doc false
  def init(:ok) do
    {:ok, %{
      backend_definitions: %{},
      backends: %{}
    }}
  end

  @doc false
  def handle_info(:refresh_backend_config, state) do
    {:noreply, do_refresh_backend_config(state)}
  end

  @doc false
  def handle_call(:refresh_backend_config, _from, state) do
    {:reply, :ok, do_refresh_backend_config(state)}
  end

  def handle_call({:get_backend, name}, _from, state) do
    case Map.fetch(state.backends, name) do
      {:ok, backend} ->
        {:reply, backend, state}
      :error ->
        do_initialize_backend(name, state)
    end
  end

  @doc false
  def code_change(_, state, _) do
    send(self, :refresh_backend_config)
    {:ok, state}
  end

  defp do_initialize_backend(name, state) do
    config_backend_defs =
      Application.get_env(:exfile, Exfile, []) |> Dict.get(:backends, %{})
    backend_defs = Map.merge(@default_backends, config_backend_defs)
    case Map.fetch(backend_defs, name) do
      {:ok, [mod, argv] = definition} ->
        argv = Dict.put(argv, :name, name)
        backend = apply(mod, :init, [argv])
        state = state
          |> put_in([:backends, name], backend)
          |> put_in([:backend_definitions, name], definition)
        {:reply, backend, state}
      :error ->
        {:reply, {:error, :backend_not_found}, state}
    end
  end

  defp do_refresh_backend_config(state) do
    put_in(state.backends, instantiate_backends(state.backend_definitions))
  end

  defp instantiate_backends(backends) do
    Enum.map(backends, fn {key, [mod, argv]} ->
      argv = Dict.put(argv, :name, key)
      {key, apply(mod, :init, [argv])}
    end) |> Enum.into(%{})
  end
end
