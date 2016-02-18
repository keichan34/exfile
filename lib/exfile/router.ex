defmodule Exfile.Router do
  use Plug.Router

  alias Exfile.Config
  alias Exfile.LocalFile

  require Logger

  plug Plug.Parsers, parsers: [:multipart]
  plug :match
  plug :dispatch

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
    |> process_file(processor)
    |> stream_file
  end

  get "/:_token/:backend/:processor/*unparsed_args" when length(unparsed_args) > 2 do
    [id, _filename] = Enum.slice(unparsed_args, -2, 2)
    args = Enum.slice(unparsed_args, 0..-3)

    authenticate(conn)
    |> download_allowed?(backend)
    |> set_file(backend, id)
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
    assign(conn, :exfile_backend_file, file)
    |> load_file
  end

  defp load_file(%{halted: true} = conn), do: conn
  defp load_file(%{assigns: %{exfile_backend_file: file}} = conn) do
    Logger.debug "[exfile] downloading file: #{inspect file}"
    case Exfile.File.download(file) do
      {:ok, local_file} ->
        assign(conn, :exfile_local_file, local_file)
      _error ->
        send_resp(conn, 404, "file not found") |> halt
    end
  end

  defp extract_format(%{path_info: path_info}) do
    filename = List.last(path_info)
    ext = String.split(filename, ".") |> List.last
    if filename == ext do
      :error
    else
      {:ok, ext}
    end
  end

  defp apply_format_processing(%{halted: true} = conn), do: conn
  defp apply_format_processing(%{path_info: path_info} = conn) do
    case extract_format(conn) do
      {:ok, ext} -> process_file(conn, "convert", [ext])
      :error -> conn
    end
  end

  defp process_file(conn, processor, args \\ [])
  defp process_file(%{halted: true} = conn, _, _), do: conn
  defp process_file(%{assigns: %{exfile_local_file: file}} = conn, processor, args) do
    opts = []
    opts = case extract_format(conn) do
      {:ok, ext} -> Keyword.put(opts, :format, ext)
      :error -> opts
    end
    case Exfile.ProcessorRegistry.process(processor, file, args, opts) do
      {:ok, processed_file} ->
        assign(conn, :exfile_local_file, processed_file)
      {:error, reason} ->
        send_resp(conn, 500, "processing using #{processor} failed with reason #{reason}") |> halt
    end
  end

  defp stream_file(%{halted: true} = conn), do: conn
  defp stream_file(%{assigns: %{exfile_local_file: %LocalFile{path: path}}} = conn) when not is_nil(path) do
    Logger.debug "[exfile] sending file via direct file"
    filename = List.last(conn.path_info)
    conn
    |> put_resp_header("content-disposition", "inline; filename=#{filename}")
    |> put_resp_header("expires", expires_header)
    |> put_resp_header("cache-control", "max-age=31540000")
    |> send_file(200, path)
  end
  defp stream_file(%{assigns: %{exfile_local_file: %LocalFile{io: io}}} = conn) when not is_nil(io) do
    Logger.debug "[exfile] sending file via IO"
    filename = List.last(conn.path_info)
    conn
    |> put_resp_header("content-disposition", "inline; filename=#{filename}")
    |> put_resp_header("expires", expires_header)
    |> put_resp_header("cache-control", "max-age=31540000")
    |> send_resp(200, IO.binread(io, :all))
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

  defp expires_header do
    {{year, _, _} = date, time} = :calendar.local_time
    date = put_elem(date, 0, year + 1)
    :httpd_util.rfc1123_date({date, time}) |> to_string
  end
end
