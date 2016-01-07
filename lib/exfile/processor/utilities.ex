defmodule Exfile.Processor.Utilities do
  @read_buffer 2048

  @doc """
  Takes a file and turns it in to a tempfile unless it already is a tempfile.
  Pass `true` as `create_new_tempfile` to force creation of a new tempfile.
  Returns a string containing the path to the tempfile.
  """
  def coerce_file_to_tempfile(file, create_new_tempfile \\ false)
  def coerce_file_to_tempfile({:tempfile, t}, false), do: t
  def coerce_file_to_tempfile({:tempfile, t}, true) do
    temp = random_tmpfile_path
    {:ok, _} = File.copy(t, temp)
    temp
  end
  def coerce_file_to_tempfile({:io, io}, _) do
    temp = random_tmpfile_path
    {:ok, true} = File.open temp, [:write, :binary], fn(f) ->
      Enum.into(
        IO.binstream(io, @read_buffer),
        IO.binstream(f, @read_buffer)
      )
      true
    end
    temp
  end

  @doc """
  Takes a file and turns it in to a io unless it already is a io.
  Returns an open io.
  """
  def coerce_file_to_io({:io, io}), do: io
  def coerce_file_to_io({:tempfile, t}) do
    {:ok, io} = File.open(t, [:read, :binary])
    io
  end

  defp random_tmpfile_path do
    random = :crypto.rand_uniform(100_000, 999_999)
    Path.join(System.tmp_dir, "exfile-#{random}")
  end
end
