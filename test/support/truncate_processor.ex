defmodule Exfile.TruncateProcessor do
  use Exfile.Processor

  def call(file, [max_length]) do
    everything = coerce_file_to_io(file) |> IO.binread(:all) |> IO.chardata_to_string
    {head, _tail} = String.split_at(everything, String.to_integer(max_length))
    {:ok, truncated_io} = File.open(head, [:ram, :binary])
    {:ok, {:io, truncated_io}}
  end
end
