defmodule Exfile.Backend.FileSystemTest do
  use Exfile.BackendTest, {
    Exfile.Backend.FileSystem,
    directory: Path.expand("./tmp/test_filesystem")
  }

  alias Exfile.LocalFile

  test "uploading a FileSystem-backed file works", c do
    string = "hello there"
    {:ok, file} = upload_string(c[:backend], string)
    {:ok, file2} = Backend.upload(c[:backend], file)

    {:ok, local_file} = Backend.open(c[:backend], file2.id)
    {:ok, open_file} = LocalFile.open(local_file)
    assert IO.read(open_file, :all) == string
  end

  test "uploading a different backend file works", c do
    backend2 = backend_mod.init(
      directory: Path.expand("./tmp/test_filesystem_2")
    )

    string = "hello there 2"

    {:ok, file} = upload_string(c[:backend], string)
    {:ok, file2} = Backend.upload(backend2, file)

    {:ok, local_file} = Backend.open(backend2, file2.id)
    {:ok, open_file} = LocalFile.open(local_file)
    assert IO.read(open_file, :all) == string
  end

  test "setting a TTL will remove files that haven't been modified for the specified number of seconds", _ do
    dir = Path.expand("./tmp/test_filesystem_3")
    File.mkdir_p!(dir)

    File.touch!(Path.join(dir, "new_file.txt"))
    File.touch!(Path.join(dir, "old_file.txt"), :calendar.universal_time |> :calendar.datetime_to_gregorian_seconds |> Kernel.-(3600) |> :calendar.gregorian_seconds_to_datetime)
    File.touch!(Path.join(dir, "future_file.txt"), :calendar.universal_time |> :calendar.datetime_to_gregorian_seconds |> Kernel.+(3600) |> :calendar.gregorian_seconds_to_datetime)

    _backend = backend_mod.init(
      directory: dir,
      ttl: 100
    )

    assert File.exists?(Path.join(dir, "new_file.txt"))
    refute File.exists?(Path.join(dir, "old_file.txt"))
    assert File.exists?(Path.join(dir, "future_file.txt"))
  end
end
