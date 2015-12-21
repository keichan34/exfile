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
    |> stream_file(file(backend, id))
  end

  # get "/:_token/:backend/:_processor/:id/:_file_basename.:extension" do
  #   authenticate(conn)
  #   |> download_allowed?(backend)
  #   |> send_resp(conn, 200, "downloading #{_file_basename}.#{extension}")

  #   # halt 404 unless download_allowed?
  #   # stream_file processor.call(file, format: params[:extension])
  # end

  # get "/:_token/:backend/:_processor/:id/:_filename" do
  #   authenticate(conn)
  #   |> download_allowed?(backend)
  #   |> send_resp(conn, 200, "downloading #{filename}")

  #   # halt 404 unless download_allowed?
  #   # stream_file processor.call(file)
  # end

  # get "/:_token/:backend/:_processor/*_args/:id/:_file_basename.:extension" do
  #   authenticate(conn)
  #   |> download_allowed?(backend)
  #   |> send_resp(conn, 200, "downloading #{_file_basename}.#{extension}")

  #   # halt 404 unless download_allowed?
  #   # stream_file processor.call(file, *params[:splat].first.split("/"), format: params[:extension])
  # end

  # get "/:_token/:backend/:_processor/*_args/:id/:_filename" do
  #   authenticate(conn)
  #   |> download_allowed?(backend)
  #   |> send_resp(conn, 200, "downloading #{_filename}")

  #   # halt 404 unless download_allowed?
  #   # stream_file processor.call(file, *params[:splat].first.split("/"))
  # end

  options "/:_backend" do
    send_resp(conn, 200, "")
  end

  post "/:backend" do
    upload_allowed?(conn, backend)
    |> process_uploaded_file(backend)

    # halt 404 unless upload_allowed?
    # tempfile = request.params.fetch("file").fetch(:tempfile)
    # file = backend.upload(tempfile)
    # content_type :json
    # { id: file.id }.to_json
  end

  # get "/:backend/presign" do
  #   halt 404 unless upload_allowed?
  #   content_type :json
  #   backend.presign.to_json
  # end

  match _ do
    send_resp(conn, 404, "file not found")
  end

  defp file(backend, id) do
    %Exfile.File{
      id: id,
      backend: Exfile.Config.backends[backend]
    }
  end

  defp stream_file(%{halted: true} = conn, _), do: conn
  defp stream_file(conn, file) do
    filename = List.last(conn.path_info)
    case Exfile.File.download(file) do
      {:ok, file} ->
        conn = conn
        |> put_resp_header("content-disposition", "inline; filename=#{filename}")
        |> send_chunked(200)
        stream = IO.binstream(file.io, @read_buffer)
        Enum.reduce stream, conn, fn(file_chunk, conn) ->
          {:ok, conn} = chunk(conn, file_chunk)
          conn
        end
        conn
      _error ->
        send_resp(conn, 404, "file not found")
    end
  end

  defp process_uploaded_file(%{halted: true} = conn, _), do: conn
  defp process_uploaded_file(conn, backend) do
    file = conn.params["file"]
    process_uploaded_file(conn, backend, file)
  end
  defp process_uploaded_file(conn, backend, %Plug.Upload{} = file) do
    {:ok, f} = File.open(file.path, [:read, :binary])
    backend = Exfile.Config.backends[backend]
    mod = backend.backend_mod
    file = mod.upload(backend, f)
    File.close(f)
    send_resp(conn, 200, "{\"id\":\"#{file.id}\"}")
  end
  defp process_uploaded_file(conn, _backend, nil) do
    send_resp(conn, 400, "please upload a file") |> halt
  end
end
