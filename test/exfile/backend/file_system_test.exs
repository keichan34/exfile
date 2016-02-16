defmodule Exfile.Backend.FileSystemTest do
  use Exfile.BackendTest, [
    Exfile.Backend.FileSystem, %{
    directory: Path.expand("./tmp/test_filesystem"),
    max_size: nil,
    hasher: Exfile.Hasher.Random
  }]

  alias Exfile.LocalFile

  test "uploading a FileSystem-backed file works", c do
    string = "hello there"
    {:ok, file} = upload_string(c[:backend], string)
    {:ok, file2} = Backend.upload(c[:backend], file)

    {:ok, local_file} = Backend.open(c[:backend], file2.id)
    {:ok, open_file} = LocalFile.open(local_file)
    assert IO.read(open_file, :all) == string
  end
end
