defmodule Exfile.Phoenix.HelpersTest.Helpers do
  alias Exfile.Token

  def a_file() do
    %Exfile.File{
      backend: %Exfile.Backend{
        backend_name: "store"
      },
      id: "file_id"
    }
  end

  def build_path(string) do
    "/attachments/" <> Token.build_path(string)
  end
end

defmodule Exfile.Phoenix.HelpersTest do
  defmodule DummyEndpoint do
    def url, do: "https://dummy.example"
  end

  use ExUnit.Case, async: true
  import Exfile.Phoenix.HelpersTest.Helpers

  alias Exfile.Phoenix.Helpers, as: H

  test "path to original file" do
    assert H.exfile_path(a_file()) == build_path("/store/file_id/file")
  end

  test "path to file with format" do
    assert H.exfile_path(a_file(), format: "jpeg") == build_path("/store/file_id/file.jpeg")
    assert H.exfile_path(a_file(), format: "png") == build_path("/store/file_id/file.png")
  end

  test "path to file with filename" do
    assert H.exfile_path(a_file(), filename: "hello-there.jpg") == build_path("/store/file_id/hello-there.jpg")
    assert H.exfile_path(a_file(), filename: "hello-there.png", format: "png") == build_path("/store/file_id/hello-there.png")
    assert H.exfile_path(a_file(), filename: "hello-there.png", format: "jpg") == build_path("/store/file_id/hello-there.png")
  end

  test "path to file with processor" do
    assert H.exfile_path(a_file(), processor: "dummy-processor") == build_path("/store/dummy-processor/file_id/file")
    assert H.exfile_path(a_file(), processor: "dummy-processor", format: "jpeg") == build_path("/store/dummy-processor/file_id/file.jpeg")
  end

  test "path to file with processor and arguments" do
    assert H.exfile_path(a_file(), processor: "dummy-processor", processor_args: ["1000", "1500"]) == build_path("/store/dummy-processor/1000/1500/file_id/file")
    assert H.exfile_path(a_file(), processor: "dummy-processor", processor_args: ["1000", "1500"], format: "jpeg") == build_path("/store/dummy-processor/1000/1500/file_id/file.jpeg")
  end

  test "URL to file using %Plug.Conn{}" do
    conn = %Plug.Conn{private: %{phoenix_endpoint: %{url: "https://phoenix.example"}}}
    assert H.exfile_url(conn, a_file()) == ("https://phoenix.example" <> build_path("/store/file_id/file"))
  end

  test "URL to file using %Plug.Conn{} with format" do
    conn = %Plug.Conn{private: %{phoenix_endpoint: %{url: "https://phoenix.example"}}}
    assert H.exfile_url(conn, a_file(), format: "jpeg") == ("https://phoenix.example" <> build_path("/store/file_id/file.jpeg"))
  end

  test "URL to file using %Phoenix.Socket{}" do
    socket = %Phoenix.Socket{endpoint: DummyEndpoint}
    assert H.exfile_url(socket, a_file()) == ("https://dummy.example" <> build_path("/store/file_id/file"))
  end

  test "URL to file using %Phoenix.Socket{} with format" do
    socket = %Phoenix.Socket{endpoint: DummyEndpoint}
    assert H.exfile_url(socket, a_file(), format: "jpeg") == ("https://dummy.example" <> build_path("/store/file_id/file.jpeg"))
  end

  test "URL to file using %URI{}" do
    uri = URI.parse("https://uri.example")
    assert H.exfile_url(uri, a_file()) == ("https://uri.example" <> build_path("/store/file_id/file"))
  end

  test "URL to file using %URI{} with format" do
    uri = URI.parse("https://uri.example")
    assert H.exfile_url(uri, a_file(), format: "jpeg") == ("https://uri.example" <> build_path("/store/file_id/file.jpeg"))
  end

  test "URL to file using an endpoint" do
    endpoint = DummyEndpoint
    assert H.exfile_url(endpoint, a_file()) == ("https://dummy.example" <> build_path("/store/file_id/file"))
  end

  test "URL to file using an endpoint with format" do
    endpoint = DummyEndpoint
    assert H.exfile_url(endpoint, a_file(), format: "jpeg") == ("https://dummy.example" <> build_path("/store/file_id/file.jpeg"))
  end

  defmodule URLWithCDNHelpersTest do
    use ExUnit.Case

    import Exfile.Phoenix.HelpersTest.Helpers
    alias Exfile.Phoenix.Helpers, as: H

    setup_all do
      original_config = Application.get_env(:exfile, Exfile, [])
      config = Keyword.put(original_config, :cdn_host, "https://exfile-host.example")
      Application.put_env(:exfile, Exfile, config)

      on_exit fn ->
        Application.put_env(:exfile, Exfile, original_config)
      end
    end

    test "URL to file" do
      assert H.exfile_url(a_file()) == ("https://exfile-host.example" <> build_path("/store/file_id/file"))
      assert H.exfile_url(a_file(), format: "jpeg") == ("https://exfile-host.example" <> build_path("/store/file_id/file.jpeg"))
    end

    test "URL to file using an endpoint will return CDN host when configured" do
      assert H.exfile_url(DummyEndpoint, a_file()) == ("https://exfile-host.example" <> build_path("/store/file_id/file"))
      assert H.exfile_url(DummyEndpoint, a_file(), format: "jpeg") == ("https://exfile-host.example" <> build_path("/store/file_id/file.jpeg"))
    end
  end
end
