defmodule Exfile.ReverseProcessor do
  @behaviour Exfile.Processor

  alias Exfile.LocalFile

  def call(file, [], _opts) do
    {:ok, f} = LocalFile.open(file)
    everything = IO.binread(f, :all) |> IO.chardata_to_string
    reversed = String.reverse(everything)
    {:ok, reversed_io} = File.open(reversed, [:ram, :binary])
    {:ok, %LocalFile{io: reversed_io}}
  end
end
