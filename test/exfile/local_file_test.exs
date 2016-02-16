defmodule Exfile.LocalFileTest do
  use ExUnit.Case, async: true

  alias Exfile.LocalFile

  @file_contents "hello there"

  def lf_with_file do
    temp = Exfile.Tempfile.random_file!("temp")
    :ok = File.write(temp, @file_contents)
    %LocalFile{path: temp}
  end

  def lf_with_io do
    temp = Exfile.Tempfile.random_file!("temp")
    :ok = File.write(temp, @file_contents)
    {:ok, io} = File.open(temp, [:read, :binary])
    %LocalFile{io: io}
  end

  def lf_with_ram_io do
    {:ok, io} = File.open(@file_contents, [:ram, :binary, :read])
    %LocalFile{io: io}
  end

  test "put_meta/3 works" do
    file = LocalFile.put_meta(%LocalFile{}, :arbitrary_meta, "hello")
    assert file.meta[:arbitrary_meta] == "hello"
  end

  test "open/1 works with a file-based LocalFile" do
    {:ok, io} = LocalFile.open(lf_with_file)
    assert IO.binread(io, :all) == @file_contents
  end

  test "open/1 works with an IO-based (normal) LocalFile" do
    {:ok, io} = LocalFile.open(lf_with_io)
    assert IO.binread(io, :all) == @file_contents
  end

  test "open/1 works with an IO-based (ram) LocalFile" do
    {:ok, io} = LocalFile.open(lf_with_ram_io)
    assert IO.binread(io, :all) == @file_contents
  end

  test "copy_to_tempfile/1 works with a file-based LocalFile" do
    file = LocalFile.copy_to_tempfile(lf_with_file)
    assert File.exists?(file.path) == true
    assert File.read!(file.path) == @file_contents
  end

  test "copy_to_tempfile/1 works with an IO-based (normal) LocalFile" do
    file = LocalFile.copy_to_tempfile(lf_with_io)
    assert File.exists?(file.path) == true
    assert File.read!(file.path) == @file_contents
  end

  test "copy_to_tempfile/1 works with an IO-based (ram) LocalFile" do
    file = LocalFile.copy_to_tempfile(lf_with_ram_io)
    assert File.exists?(file.path) == true
    assert File.read!(file.path) == @file_contents
  end
end
