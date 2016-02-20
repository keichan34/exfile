defmodule Exfile.ErrorProcessor do
  @behaviour Exfile.Processor

  def call(_, _, opts) do
    error = Keyword.get(opts, :error, :something)
    {:error, error}
  end
end
