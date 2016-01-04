defmodule Exfile.Router do
  use Plug.Router

  alias Exfile.Config

  plug Plug.Parsers, parsers: [:multipart]
  plug :match
  plug :dispatch

  @read_buffer 2048

  defp authenticate(%{path_info: path_info} = conn) do
    [token | rest] = path_info
    request_path = rest |> Enum.join("/")
    if Exfile.Token.verify_token(request_path, token) do
      conn
    else
      send_resp(conn, 403, "forbidden") |> halt
    end
  end

  defp download_allowed?(%{halted: true} = conn, _), do: conn
  defp download_allowed?(conn, backend) do
    backends = Config.allow_downloads_from
    if backends == :all || Enum.member?(backends, backend) do
      conn
    else
      send_resp(conn, 404, "file not found (backend invalid)") |> halt
    end
  end

  defp upload_allowed?(%{halted: true} = conn, _), do: conn
  defp upload_allowed?(conn, backend) do
    backends = Config.allow_uploads_to
    if backends == :all || Enum.member?(backends, backend) do
      conn
    else
      send_resp(conn, 404, "file not found (backend invalid)") |> halt
    end
  end

  get "/:_token/:backend/:id/:_filename" do
    authenticate(conn)
    |> download_allowed?(backend)
    |> set_file(backend, id)
    |> apply_format_processing
    |> stream_file
  end

  get "/:_token/:backend/:processor/:id/:_filename" do
    authenticate(conn)
    |> download_allowed?(backend)
    |> set_file(backend, id)
    |> apply_format_processing
    |> process_file(processor)
    |> stream_file
  end

  get "/:_token/:backend/:processor/*unparsed_args" when length(unparsed_args) > 2 do
    [id, _filename] = Enum.slice(unparsed_args, -2, 2)
    args = Enum.slice(unparsed_args, 0..-3)

    authenticate(conn)
    |> download_allowed?(backend)
    |> set_file(backend, id)
    |> apply_format_processing
    |> process_file(processor, args)
    |> stream_file
  end

  options "/:_backend" do
    send_resp(conn, 200, "")
  end

  post "/:backend" do
    upload_allowed?(conn, backend)
    |> process_uploaded_file(backend)
  end

  # get "/:backend/presign" do
  #   halt 404 unless upload_allowed?
  #   content_type :json
  #   backend.presign.to_json
  # end

  match _ do
    send_resp(conn, 404, "file not found")
  end

  defp set_file(%{halted: true} = conn, _, _), do: conn
  defp set_file(conn, backend, id) do
    file = %Exfile.File{
      id: id,
      backend: Config.get_backend(backend)
    }
    assign(conn, :exfile_file, file)
  end

  defp apply_format_processing(%{halted: true} = conn), do: conn
  defp apply_format_processing(%{path_info: path_info} = conn) do
    filename = List.last(conn.path_info)
    ext = String.split(filename, ".") |> List.last
    if filename == ext do
      conn
    else
      process_file(conn, "convert", [ext])
    end
  end

  defp process_file(conn, processor, args \\ [])
  defp process_file(%{halted: true} = conn, _, _), do: conn
  defp process_file(%{assigns: %{exfile_file: file}} = conn, processor, args) do
    case Exfile.ProcessorRegistry.process(processor, file, args) do
      {:ok, {:io, io}} ->
        assign(conn, :exfile_file_io, io)
      {:ok, {:tempfile, tempfile}} ->
        assign(conn, :exfile_sendfile, tempfile)
      {:error, reason} ->
        send_resp(conn, 500, "processing using #{processor} failed with reason #{reason}") |> halt
    end
  end

  defp stream_file(%{halted: true} = conn), do: conn
  defp stream_file(%{assigns: %{exfile_sendfile: path}} = conn) do
    filename = List.last(conn.path_info)
    conn
    |> put_resp_header("content-disposition", "inline; filename=#{filename}")
    |> send_file(200, path)
  end
  defp stream_file(%{assigns: %{exfile_file_io: io}} = conn) do
    filename = List.last(conn.path_info)
    conn = conn
    |> put_resp_header("content-disposition", "inline; filename=#{filename}")
    |> send_chunked(200)

    IO.binstream(io, @read_buffer)
    |> Enum.into(conn)
  end
  defp stream_file(%{assigns: %{exfile_file: file}} = conn) do
    case Exfile.File.download(file) do
      {:ok, io} ->
        assign(conn, :exfile_file_io, io) |> stream_file
      _error ->
        send_resp(conn, 404, "file not found") |> halt
    end
  end

  defp process_uploaded_file(%{halted: true} = conn, _), do: conn
  defp process_uploaded_file(conn, backend) do
    file = conn.params["file"]
    process_uploaded_file(conn, backend, file)
  end
  defp process_uploaded_file(conn, backend, %Plug.Upload{} = uploaded_file) do
    {:ok, f} = File.open(uploaded_file.path, [:read, :binary])
    backend = Config.get_backend(backend)
    {:ok, file} = Exfile.Backend.upload(backend, f)
    File.close(f)

    put_resp_content_type(conn, "application/json")
    |> send_resp(200, "{\"id\":\"#{file.id}\"}")
  end
  defp process_uploaded_file(conn, _backend, nil) do
    send_resp(conn, 400, "please upload a file") |> halt
  end
end
