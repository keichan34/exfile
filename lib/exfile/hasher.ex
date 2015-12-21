defmodule Exfile.Hasher do
  @type file_id :: String.t
  @type uploadable :: :file.io_device

  @callback hash(uploadable) :: file_id
end
