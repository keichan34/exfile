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
    temp = Exfile.Tempfile.random_file!("reverse-tempfile")
    :ok = File.write(Path.expand(temp), string)
    temp
  end
end
