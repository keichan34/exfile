defmodule Exfile.Hasher.Random do
  @behaviour Exfile.Hasher

  def hash(_uploadable) do
    :crypto.rand_bytes(30) |> Base.encode16(case: :lower)
  end
end
