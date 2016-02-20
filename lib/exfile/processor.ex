defmodule Exfile.Processor do
  @moduledoc """
  A behaviour defining the API a Processor should adhere to.
  """

  @type file :: %Exfile.LocalFile{}

  @doc """
  Processes the file, returns {:ok, result} on success or {:error, reason} on failure.
  """
  @callback call(file, [String.t, ...], [...]) :: {:ok, file} | {:error, atom}
end
