defmodule Exfile.Hasher do
  @moduledoc """
  A behaviour defining a module to generate a file ID.

  The File ID will be used as the filename on the backend storage.
  """

  @type file_id :: String.t
  @type uploadable :: %Exfile.LocalFile{}

  @callback hash(uploadable) :: file_id
end
