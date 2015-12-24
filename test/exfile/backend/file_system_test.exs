defmodule Exfile.Backend.FileSystemTest do
  use Exfile.BackendTest, [
    Exfile.Backend.FileSystem, %{
    directory: Path.expand("./tmp/test_filesystem"),
    max_size: nil,
    hasher: Exfile.Hasher.Random
  }]
end
