defmodule Exfile.ReverseTempfileProcessor do
  @behaviour Exfile.Processor

  def call(file, []) do
    {:ok, open_io} = Exfile.File.download(file)
    tempfile_path =
       IO.read(open_io, :all)
    |> String.reverse
    |> into_tempfile

    {:ok, {:tempfile, tempfile_path}}
  end

  defp into_tempfile(string) do
    random = :crypto.rand_uniform(100_000, 999_999)
    temp = Path.join(System.tmp_dir, "#{random}-reverse.txt")

    :ok = File.write(Path.expand(temp), string)
    temp
  end
end
