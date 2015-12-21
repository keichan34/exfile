defmodule Exfile.Hasher.Random do
  @behaviour Exfile.Hasher

  def hash(_uploadable) do
    :crypto.rand_bytes(20)
    |> :erlang.bitstring_to_list
    |> Enum.map(fn (x) -> :erlang.integer_to_binary(x, 16) end)
    |> Enum.join
    |> String.downcase
  end
end
