defmodule Exfile.ReverseProcessor do
  use Exfile.Processor

  def call(file, []) do
    everything = coerce_file_to_io(file) |> IO.binread(:all) |> IO.chardata_to_string
    reversed = String.reverse(everything)
    {:ok, reversed_io} = File.open(reversed, [:ram, :binary])
    {:ok, {:io, reversed_io}}
  end
end
