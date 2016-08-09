defmodule Exfile.Supervisor do
  @moduledoc false

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

    children = if Mix.env == :test do
      children ++ [
        worker(Exfile.Repo, [])
      ]
    end

    supervise(children, strategy: :one_for_one)
  end
end
