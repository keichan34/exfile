defmodule Exfile.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Exfile.Router
  alias Exfile.Token

  @opts Router.init([])

  test "returns 403 (forbidden) on invalid token request" do
    conn = conn(:get, "/invalid-token/cache/1234/test.txt")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 403
    assert conn.resp_body == "forbidden"
  end

  test "returns 404 (file not found) on request to file that does not exist" do
    conn = conn(:get, "/" <> Token.build_path("cache/1234/test.txt"))
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "file not found"
  end

  test "returns 200 on request to file that exists" do
    :ok = File.touch(Path.expand("./tmp/cache/exists"))
    conn = conn(:get, "/" <> Token.build_path("cache/exists/test.txt"))
    conn = Router.call(conn, @opts)

    assert conn.state == :chunked
    assert conn.status == 200
  end

  test "returns 200 on an OPTIONS request to /:backend" do
    conn = conn(:options, "/some-backend")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returs 404 (file not found) on a upload to a disallowed backend" do
    conn = conn(:post, "/store")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "file not found (backend invalid)"
  end

  test "returns 200 and a valid JSON object containing the file ID on a POST to /:backend" do
    path = Plug.Upload.random_file!("multipart")
    upload =  %Plug.Upload{filename: "file", path: path,
                           content_type: "application/octet-stream"}
    body = %{"file" => upload}
    conn = conn(:post, "/cache", body)
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["id"] != nil

    assert File.exists?(Path.expand("./tmp/cache/#{body["id"]}")) == true
  end
end
