defmodule Exfile.Phoenix.Helpers do
  alias Exfile.Token

  def file_path(%Exfile.File{} = file) do
    path = "#{file.backend.backend_name}/#{file.id}/file"
    "/attachments/" <> Token.build_path(path)
  end

  def file_path(%Exfile.File{} = file, format: format) do
    path = "#{file.backend.backend_name}/#{file.id}/file.#{format}"
    "/attachments/" <> Token.build_path(path)
  end
end
