defmodule Exfile.Ecto.FileTemplateTest do
  use ExUnit.Case, async: true

  defmodule TestFile do
    use Exfile.Ecto.FileTemplate, backend: "store", cache_backend: "cache"
  end

  import Ecto.Type

  def backend(), do: Exfile.Config.get_backend("cache")
  def store_backend(), do: Exfile.Config.get_backend("store")
  def store2_backend(), do: Exfile.Config.get_backend("store2")

  def file_contents_equal(file, contents) do
    {:ok, local_file} = Exfile.File.open(file)
    {:ok, io} = Exfile.LocalFile.open(local_file)
    IO.binread(io, :all) == contents
  end

  setup do
    file_contents = "hello there"
    {:ok, io} = File.open(file_contents, [:ram, :binary, :read])
    local_file = %Exfile.LocalFile{io: io}
    {:ok, file} = Exfile.Backend.upload(backend(), local_file)
    # rewind the io because it's been read in the upload process above
    :file.position(io, :bof)

    {:ok, store_file} = Exfile.Backend.upload(store_backend(), local_file)
    # rewind the io because it's been read in the upload process above
    :file.position(io, :bof)

    {:ok, store2_file} = Exfile.Backend.upload(store2_backend(), local_file)
    # rewind the io because it's been read in the upload process above
    :file.position(io, :bof)

    {:ok, %{
      file_contents: file_contents,
      cache_file: file,
      store_file: store_file,
      store2_file: store2_file,
      local_file: local_file
    }}
  end

  test "casting a Exfile.File returns a new Exfile.File", %{store2_file: file, file_contents: file_contents} do
    {:ok, new_file} = cast(TestFile, file)

    assert %Exfile.File{} = new_file
    assert new_file.id != file.id
    assert file_contents_equal(new_file, file_contents)
  end

  test "casting a Exfile.LocalFile returns a new Exfile.File", %{local_file: local_file, file_contents: file_contents} do
    {:ok, new_file} = cast(TestFile, local_file)

    assert %Exfile.File{} = new_file
    assert file_contents_equal(new_file, file_contents)
  end

  test "casting a Plug.Upload returns a new Exfile.File", _ do
    file_contents = "hello there contents"
    path = Plug.Upload.random_file!("exfile")
    :ok = File.write!(path, file_contents)
    upload = %Plug.Upload{path: path}
    {:ok, new_file} = cast(TestFile, upload)

    assert %Exfile.File{} = new_file
    assert file_contents_equal(new_file, file_contents)
  end

  test "casting a string binary representing an existing file works", %{cache_file: file, file_contents: file_contents} do
    {:ok, new_file} = cast(TestFile, "exfile://cache/" <> file.id)

    assert %Exfile.File{} = new_file
    assert new_file.backend == file.backend
    assert new_file.id == file.id
    assert file_contents_equal(new_file, file_contents)
  end

  test "casting a string binary representing an existing file on a different backend works" do
    file_contents = "hello there"
    {:ok, io} = File.open(file_contents, [:ram, :binary, :read])
    local_file = %Exfile.LocalFile{io: io}
    {:ok, file} = Exfile.Backend.upload(store2_backend(), local_file)
    # rewind the io because it's been read in the upload process above
    :file.position(io, :bof)

    {:ok, new_file} = cast(TestFile, "exfile://store2/" <> file.id)

    assert %Exfile.File{} = new_file
    assert new_file.backend == backend()
    refute new_file.id == file.id
    assert file_contents_equal(new_file, file_contents)
  end

  test "loading a binary from the database returns a valid Exfile.File", %{store_file: file} do
    assert {:ok, ^file} = load(TestFile, file.id)
  end

  test "dumping an Exfile.File returns the correct file URI", %{cache_file: file} do
    assert {:ok, Exfile.File.uri(file)} == dump(TestFile, file)
  end

  test "the type is :string", _ do
    assert TestFile.type == :string
  end

  test "upload!/1 takes an Exfile.File in the cache backend and uploads it to the store backend", %{cache_file: file} do
    assert file.backend == backend()
    assert {:ok, store_file} = TestFile.upload!(file)
    assert store_file.backend == store_backend()
  end
end
