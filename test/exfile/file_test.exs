defmodule Exfile.FileTest do
  use ExUnit.Case, async: true

  def backend, do: Exfile.Config.get_backend("cache")

  setup do
    file_contents = "hello there"
    {:ok, io} = File.open(file_contents, [:ram, :binary, :read])
    local_file = %Exfile.LocalFile{io: io}
    {:ok, file} = Exfile.Backend.upload(backend(), local_file)
    # rewind the io because it's been read in the upload process above
    :file.position(io, :bof)

    {:ok, %{backend_file: file}}
  end

  test "get the URI of the file", %{backend_file: file} do
    uri = Exfile.File.uri(file) |> URI.parse
    assert uri.scheme == "exfile"
    assert uri.host == "cache"
    assert uri.path == "/" <> file.id
  end
end
