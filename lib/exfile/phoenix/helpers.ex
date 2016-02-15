defmodule Exfile.Phoenix.Helpers do
  alias Exfile.Token

  @doc """
  Returns the absolute path of a file with the options passed.
  """
  def exfile_path(%Exfile.File{} = file, opts \\ []) do
    path = [file.backend.backend_name]

    case Dict.fetch(opts, :processor) do
      {:ok, processor} ->
        path = path ++ [processor]
      :error -> nil
    end

    case Dict.fetch(opts, :processor_args) do
      {:ok, processor_args} ->
        path = path ++ processor_args
      :error -> nil
    end

    format = Dict.get(opts, :format)
    format_ext = if format, do: "." <> format
    path = path ++ [file.id, "file#{format_ext}"]

    "/attachments/" <> (Enum.join(path, "/") |> Token.build_path)
  end

  @doc """
  Returns the absolute URL of a file with the options passed. The first argument
  accepts any parameter that the Phoenix generated _url function takes.
  """
  def exfile_url(conn_or_endpoint, file, opts \\ []) do
    Phoenix.Router.Helpers.url(nil, conn_or_endpoint) <> exfile_path(file, opts)
  end
end
