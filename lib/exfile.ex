defmodule Exfile do
  use Application

  @doc false
  def start(_type, _args) do
    Exfile.Supervisor.start_link()
  end
end
