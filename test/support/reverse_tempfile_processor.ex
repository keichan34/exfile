defmodule Exfile.ReverseTempfileProcessor do
  use Exfile.Processor

  def call(file, []) do
    tempfile_path =
       coerce_file_to_io(file)
    |> IO.binread(:all)
    |> IO.chardata_to_string
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
