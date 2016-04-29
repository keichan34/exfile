defmodule Exfile.Config do
  @default_backends %{
    "store" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/store"),
      max_size: nil,
      hasher: Exfile.Hasher.Random
    },
    "cache" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/cache"),
      max_size: nil,
      hasher: Exfile.Hasher.Random
    }
  }

  @moduledoc """
  A simple server responsible for Exfile configuration.

  The default configuration:

  ```
  %{
    "store" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/store"),
      max_size: nil,
      hasher: Exfile.Hasher.Random
    },
    "cache" => {Exfile.Backend.FileSystem,
      directory: Path.expand("./tmp/cache"),
      max_size: nil,
      hasher: Exfile.Hasher.Random
    }
  }
  ```
  """

  @default_config [
    allow_downloads_from: :all,
    allow_uploads_to: ["cache"],
    secret: nil,
    cdn_host: nil
  ]

  Enum.each @default_config, fn {key, _default} ->
    @doc """
    Get "#{key}". Defaults to #{inspect @default_config[key]}
    """
    def unquote(key)() do
      Application.get_env(:exfile, Exfile, [])
      |> Keyword.get(unquote(key), @default_config[unquote(key)])
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
    case GenServer.call(__MODULE__, {:get_backend, name}) do
      {:ok, backend} -> backend
      {:error, error} ->
        raise ~s(The backend #{name} couldn't be initialized: #{error})
    end
  end

  @doc """
  Re-initialize all registered backends
  """
  def refresh_backend_config(timeout \\ 5_000) do
    GenServer.call(__MODULE__, :refresh_backend_config, timeout)
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
        {:reply, {:ok, backend}, state}
      :error ->
        case initialize_backend(name, state) do
          {:error, _} = error -> {:reply, error, state}
          {reply, state} -> {:reply, reply, state}
        end
    end
  end

  @doc false
  def code_change(_, state, _) do
    send(self, :refresh_backend_config)
    {:ok, state}
  end

  defp initialize_backend(name, state) do
    with  {:ok, definition} <- fetch_backend_definition(name),
          {:ok, backend} <- init_backend_from_definition(name, definition) do
            state = state
            |> put_in([:backends, name], backend)
            |> put_in([:backend_definitions, name], definition)
            {{:ok, backend}, state}
          end
  end

  defp fetch_backend_definition(name) do
    config_backend_defs =
      Application.get_env(:exfile, Exfile, []) |> Keyword.get(:backends, %{})
    backend_defs = Map.merge(@default_backends, config_backend_defs)
    case Map.fetch(backend_defs, name) do
      {:ok, definition} -> {:ok, definition}
      :error -> {:error, :backend_not_found}
    end
  end

  defp init_backend_from_definition(name, {mod, argv}) do
    argv = Keyword.put(argv, :name, name)
    case apply(mod, :init, [argv]) do
      {:error, _} = error -> error
      backend -> {:ok, backend}
    end
  end

  defp do_refresh_backend_config(state) do
    put_in(state.backends, init_backends_from_definitions(state.backend_definitions))
  end

  defp init_backends_from_definitions(definitions) do
    definitions
    |> Enum.map(fn({name, definition}) ->
        backend = init_backend_from_definition(name, definition)
        {name, backend}
      end)
    |> Enum.filter(fn
        ({_, {:ok, _}}) -> true
        _ -> false
      end)
    |> Enum.map(fn({name, {:ok, backend}}) ->
        {name, backend}
      end)
    |> Enum.into(%{})
  end
end
