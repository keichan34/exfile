defmodule Exfile.Processor do
  @moduledoc """
  A behaviour defining the API a Processor should adhere to.
  """

  @type file :: Exfile.LocalFile.t

  @doc """
  Processes the file, returns {:ok, result} on success or {:error, reason} on failure.
  """
  @callback call(file, [String.t, ...]) :: {:ok, file} | {:error, atom}

  defmacro __using__(_) do
    quote do
      @behaviour Exfile.Processor
      import Exfile.Processor.Utilities
    end
  end
end
