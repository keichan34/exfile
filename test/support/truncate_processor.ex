defmodule Exfile.TruncateProcessor do
  @behaviour Exfile.Processor

  def call(file, [max_length]) do
    {:ok, open_file} = Exfile.File.download(file)
    everything = IO.read(open_file.io, :all)
    {head, _tail} = String.split_at(everything, String.to_integer(max_length))
    {:ok, truncated_io} = StringIO.open(head)
    processed_file = put_in(file.io, truncated_io)
    {:ok, processed_file}
  end
end
