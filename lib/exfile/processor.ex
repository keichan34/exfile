defmodule Exfile.Processor do
  @moduledoc """
  A behaviour defining the API a Processor should adhere to.
  """

  @type file :: Exfile.File.t

  @type processed_result :: {:tempfile, Path.t} | {:io, pid}

  @doc """
  Processes the file, returns {:ok, result} on success or {:error, reason} on failure.
  """
  @callback call(file, [String.t, ...]) :: {:ok, processed_result} | {:error, atom}
end
