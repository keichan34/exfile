defmodule Exfile.ProcessorRegistry do
  use GenServer

  @type file :: Exfile.File.t
  @type processor_name :: String.t
  @type processor_module :: atom

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @spec register(processor_name, processor_module) :: :ok
  def register(name, module) do
    GenServer.call(__MODULE__, {:register, name, module})
  end

  @spec process(processor_name, file, [...]) :: {:ok, file} | {:error, atom}
  # @spec process(processor_name, [...], String.t) :: :ok | {:error, atom}
  def process(name, file, args) do
    case GenServer.call(__MODULE__, {:processor, name}) do
      {:ok, module} ->
        apply(module, :call, [file, args])
      :error ->
        {:error, :no_processor}
    end
  end

  ## Callbacks

  @doc false
  def init(:ok) do
    {:ok, %{
      processors: %{}
    }}
  end

  def handle_call({:register, name, module}, _from, state) do
    state = put_in(state.processors[name], module)
    {:reply, :ok, state}
  end

  def handle_call({:processor, name}, _from, state) do
    {
      :reply,
      Map.fetch(state.processors, name),
      state
    }
  end
end
