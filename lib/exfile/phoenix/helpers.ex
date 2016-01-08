defmodule Exfile.Phoenix.Helpers do
  alias Exfile.Token

  def file_path(%Exfile.File{} = file, opts \\ []) do
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
end
