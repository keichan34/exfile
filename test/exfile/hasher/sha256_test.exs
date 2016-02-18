defmodule Exfile.Hasher.SHA256Test do
  use ExUnit.Case, async: true

  alias Exfile.LocalFile

  @hasher Exfile.Hasher.SHA256

  test "returns a correct SHA256 for a memory-based LocalFile" do
    {:ok, io} = File.open("hello there", [:ram, :binary, :read])
    file = %LocalFile{io: io}
    assert @hasher.hash(file) == "12998c017066eb0d2a70b94e6ed3192985855ce390f321bbdb832022888bd251"
  end

  test "returns a correct SHA256 for a temporary file IO-based LocalFile" do
    {:ok, path} = Exfile.Tempfile.random_file("sample")
    {:ok, io} = File.open(path, [:binary, :read])
    file = %LocalFile{io: io}
    assert @hasher.hash(file) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  end

  test "returns a correct SHA256 for a temporary file-based LocalFile" do
    {:ok, path} = Exfile.Tempfile.random_file("sample")
    file = %LocalFile{path: path}
    assert @hasher.hash(file) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  end
end
