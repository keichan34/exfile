defmodule Exfile.TruncateProcessor do
  @behaviour Exfile.Processor

  def call(file, [max_length]) do
    {:ok, open_io} = Exfile.File.download(file)
    everything = IO.read(open_io, :all)
    {head, _tail} = String.split_at(everything, String.to_integer(max_length))
    {:ok, truncated_io} = File.open(head, [:ram, :binary])
    {:ok, {:io, truncated_io}}
  end
end
