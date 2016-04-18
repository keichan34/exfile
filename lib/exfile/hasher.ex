defmodule Exfile.Hasher do
  @moduledoc """
  A behaviour defining a module to generate a file ID.

  The File ID will be used as the filename on the backend storage.
  """

  @type uploadable :: Exfile.LocalFile.t

  @callback hash(uploadable) :: Exfile.File.file_id
end
