defmodule Exfile.Hasher.SHA256 do
  @behaviour Exfile.Hasher

  def hash(uploadable) when is_binary(uploadable) do
    hash(File.open(uploadable, [:read, :binary]))
  end

  def hash(%Exfile.File{} = uploadable) do
    hash(Exfile.File.download(uploadable))
  end

  def hash(io) do
    ctx = :crypto.hash_init(:sha256)
    hash = IO.binstream(io, 2048) |> Enum.reduce(ctx, fn(buf, ctx) ->
        :crypto.hash_update(ctx, buf)
      end)
      |> :crypto.hash_final
      |> Base.encode16(case: :lower)

    # Reading from an io is side-effect-ful, so we have to rewind it before
    # we're done here.
    :file.position(io, :bof)

    hash
  end
end
