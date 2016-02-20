defmodule Exfile.ReverseTempfileProcessor do
  @behaviour Exfile.Processor

  alias Exfile.LocalFile

  def call(file, [], _opts) do
    {:ok, f} = LocalFile.open(file)
    tempfile_path =
       IO.binread(f, :all)
    |> IO.chardata_to_string
    |> String.reverse
    |> into_tempfile

    {:ok, %LocalFile{path: tempfile_path}}
  end

  defp into_tempfile(string) do
    temp = Exfile.Tempfile.random_file!("reverse-tempfile")
    :ok = File.write(Path.expand(temp), string)
    temp
  end
end
