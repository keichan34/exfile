defmodule Exfile.Phoenix.Helpers do
  alias Exfile.Token

  def file_path(%Exfile.File{} = file, opts \\ []) do
    format = Dict.get(opts, :format)
    format_ext = if format, do: "." <> format
    path = [file.backend.backend_name, file.id, "file#{format_ext}"]
    "/attachments/" <> (Enum.join(path, "/") |> Token.build_path)
  end
end
