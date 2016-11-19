defmodule Exfile.Processor.FileSizeTest do
  use ExUnit.Case, async: true

  alias Exfile.Processor.FileSize, as: FileSizeProcessor
  alias Exfile.LocalFile

  test "it works" do
    file = %LocalFile{ path: "test/fixtures/sample.jpg" }
    { :ok, processed_file } = FileSizeProcessor.call(file, [], [])

    assert processed_file.meta["file_size"] == 631
  end

  test "returns error on a nonexistant file" do
    file = %LocalFile{ path: "nonexistant.jpg" }
    result = FileSizeProcessor.call(file, [], [])

    assert result == { :error, :unable_to_read_file }
  end

  test "process on file only once" do
    file = %LocalFile{ path: "test/fixtures/sample.jpg", meta: %{ "file_size" => 311 } }
    { :ok, processed_file } = FileSizeProcessor.call(file, [], [])

    assert processed_file.meta["file_size"] == 311
  end
end
