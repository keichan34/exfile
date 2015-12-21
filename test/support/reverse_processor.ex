defmodule Exfile.ReverseProcessor do
  @behaviour Exfile.Processor

  def call(file, []) do
    {:ok, open_file} = Exfile.File.download(file)
    everything = IO.read(open_file.io, :all)
    reversed = String.reverse(everything)
    {:ok, reversed_io} = StringIO.open(reversed)
    processed_file = put_in(file.io, reversed_io)
    {:ok, processed_file}
  end
end
