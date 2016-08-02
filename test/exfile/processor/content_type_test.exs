defmodule Exfile.Processor.ContentTypeTest do
  use ExUnit.Case, async: true

  alias Exfile.LocalFile

  test "it works" do
    file = %LocalFile{ path: "test/fixtures/sample.jpg" }
    { :ok, processed_file } = Exfile.Processor.ContentType.call(file, [], [])

    assert processed_file.meta["content_type"] == "image/jpeg"
  end

  test "returns error on a nonexistant file" do
    file = %LocalFile{ path: "nonexistant.jpg" }
    result = Exfile.Processor.ContentType.call(file, [], [])

    assert result == { :error, :unable_to_read_file }
  end

  test "process on file only once" do
    file = %LocalFile{ path: "test/fixtures/sample.jpg", meta: %{ "content_type" => "already-computed-content-type" } }
    { :ok, processed_file } = Exfile.Processor.ContentType.call(file, [], [])

    assert processed_file.meta["content_type"] == "already-computed-content-type"
  end
end
