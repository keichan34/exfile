defmodule Exfile.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Exfile.Router
  alias Exfile.Token

  @opts Router.init([])

  test "returns 403 (forbidden) on invalid token request" do
    conn = conn(:get, "/invalid-token/cache/1234/test")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 403
    assert conn.resp_body == "forbidden"
  end

  test "returns 404 (file not found) on request to file that does not exist" do
    conn = conn(:get, Token.build_path("/cache/1234/test"))
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "file not found"
  end

  test "returns 200 on request to file that exists" do
    contents = "hello there"
    :ok = File.write(Path.expand("./tmp/cache/exists"), contents)
    conn = conn(:get, Token.build_path("/cache/exists/test"))
    conn = Router.call(conn, @opts)

    assert conn.state == :file
    assert conn.status == 200
    assert conn.resp_body == contents

    [content_type_string | _] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type_string == "text/plain"

    [expires_string | _] = Plug.Conn.get_resp_header(conn, "expires")
    {:ok, expires} = Timex.parse(expires_string, "%a, %d %b %Y %H:%M:%S GMT", :strftime)

    valid_date = Timex.Date.now |> Timex.add(Timex.Time.to_timestamp(180, :days))
    expired_date = Timex.Date.now |> Timex.add(Timex.Time.to_timestamp(540, :days))

    assert Timex.Date.compare(expires, valid_date) == 1
    assert Timex.Date.compare(expires, expired_date) == -1
  end

  test "returns 304 (not modified) on request with valid if-none-match" do
    path = "/cache/test/test"
    token = Token.generate_token(path)
    path = Path.join(token, path)
    conn = conn(:get, path, "") |> put_req_header("if-none-match", token)
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 304
    assert conn.resp_body == ""
  end

  test "returns correctly processed file" do
    contents = "hello there"
    :ok = File.write(Path.expand("./tmp/cache/processtest"), contents)
    conn = conn(:get, Token.build_path("/cache/reverse/processtest/test"))
    conn = Router.call(conn, @opts)

    assert conn.state == :file
    assert conn.status == 200
    assert conn.resp_body == String.reverse(contents)

    [content_type_string | _] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type_string == "text/plain"
  end

  test "returns correctly processed file when processor saves to a tempfile" do
    contents = "hello there"
    :ok = File.write(Path.expand("./tmp/cache/processtest-tempfile"), contents)
    conn = conn(:get, Token.build_path("/cache/reverse-tempfile/processtest-tempfile/test"))
    conn = Router.call(conn, @opts)

    assert conn.state == :file
    assert conn.status == 200
    assert conn.resp_body == String.reverse(contents)

    [content_type_string | _] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type_string == "text/plain"
  end

  test "returns correctly processed file with arguments" do
    contents = "hello there"
    :ok = File.write(Path.expand("./tmp/cache/process-arg-test"), contents)
    conn = conn(:get, Token.build_path("/cache/truncate/5/process-arg-test/test"))
    conn = Router.call(conn, @opts)

    assert conn.state == :file
    assert conn.status == 200
    assert conn.resp_body == "hello"

    [content_type_string | _] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type_string == "text/plain"
  end

  test "returns 200 on an OPTIONS request to /:backend" do
    conn = conn(:options, "/some-backend")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns 404 (file not found) on a upload to a disallowed backend" do
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
    assert body["uri"] == "exfile://cache/" <> body["id"]

    assert File.exists?(Path.expand("./tmp/cache/#{body["id"]}")) == true
  end

  test "returns 422 and a valid JSON object containing error details on a POST to /:backend when the file failed to upload" do
    path = Plug.Upload.random_file!("multipart")
    contents = """
    hello there, how are you doing? this string is more than 100 bytes and
    should fail the uploading process!!
    """
    File.write(path, contents)
    upload =  %Plug.Upload{filename: "file", path: path,
                           content_type: "application/octet-stream"}
    body = %{"file" => upload}
    conn = conn(:post, "/limited", body)
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 422

    body = Poison.decode!(conn.resp_body)
    assert body["error"] == true
    assert body["error_message"] == "too_big"
  end
end
