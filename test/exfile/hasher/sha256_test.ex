defmodule Exfile.Hasher.SHA256Test do
  use ExUnit.Case, async: true

  @hasher Exfile.Hasher.SHA256

  test "returns a correct SHA256 for a memory-based IO" do
    {:ok, io} = File.open("hello there", [:ram, :binary, :read])
    assert @hasher.hash(io) == "12998c017066eb0d2a70b94e6ed3192985855ce390f321bbdb832022888bd251"
  end

  test "returns a correct SHA256 for a temporary file-based IO" do
    {:ok, path} = Exfile.Tempfile.random_file("sample")
    {:ok, io} = File.open(path, [:binary, :read])
    assert @hasher.hash(io) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  end
end
