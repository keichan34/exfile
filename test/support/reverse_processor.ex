defmodule Exfile.ReverseProcessor do
  @behaviour Exfile.Processor

  def call(file, []) do
    {:ok, open_io} = Exfile.File.download(file)
    everything = IO.read(open_io, :all)
    reversed = String.reverse(everything)
    {:ok, reversed_io} = File.open(reversed, [:ram, :binary])
    {:ok, {:io, reversed_io}}
  end
end
