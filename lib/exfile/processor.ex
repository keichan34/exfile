defmodule Exfile.Processor do
  @moduledoc """
  A behaviour defining the API a Processor should adhere to.
  """

  @type file :: Exfile.File.t

  @doc """
  A processor can elect to make its results available either in a temporary file
  saved to the local filesystem or as a pid of an open IO.
  """
  @type processed_result :: {:tempfile, Path.t} | {:io, pid}

  @doc """
  Processes the file, returns {:ok, result} on success or {:error, reason} on failure.
  """
  @callback call(file, [String.t, ...]) :: {:ok, processed_result} | {:error, atom}
end
