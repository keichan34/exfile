defmodule Exfile.Hasher.SHA256 do
  @behaviour Exfile.Hasher

  alias Exfile.LocalFile

  def hash(%LocalFile{} = uploadable) do
    {:ok, io} = LocalFile.open(uploadable)
    ctx = :crypto.hash_init(:sha256)
    hash = IO.binstream(io, 2048) |> Enum.reduce(ctx, fn(buf, ctx) ->
        :crypto.hash_update(ctx, buf)
      end)
      |> :crypto.hash_final
      |> Base.encode16(case: :lower)

    hash
  end
end
