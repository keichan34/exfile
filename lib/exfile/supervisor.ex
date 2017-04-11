defmodule Exfile.Supervisor do
  @moduledoc false

  defmacrop test_children do
    if Mix.env == :test do
      quote do
        [Supervisor.Spec.worker(Exfile.Repo, [])]
      end
    else
      quote do: []
    end
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(Exfile.Tempfile, []),
      worker(Exfile.Config, []),
      worker(Exfile.ProcessorRegistry, []),
    ]

    children = children ++ test_children()

    supervise(children, strategy: :one_for_one)
  end
end
