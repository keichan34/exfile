defmodule Exfile.Processor.ContentType do
  @behaviour Exfile.Processor

  def call(file = %{ meta: %{ "content_type" => content_type }}, _, _) when is_binary(content_type) do
    { :ok, file }
  end

  def call(file, _, _) do
    local_file = Exfile.ProcessorChain.coerce_to_local_file(file)
    if File.exists?(local_file.path) do
      perform_file_cmd(file, local_file)
    else
      { :error, :unable_to_read_file }
    end
  end

  defp perform_file_cmd(file, local_file) do
    case System.cmd("file", ["--mime-type", local_file.path]) do
      { result, 0 } ->
        meta = Map.merge(local_file.meta, extract_meta(result))
        { :ok, %{ file | meta: meta }}
      _             -> { :error, :unable_to_read_file }
    end
  end

  defp extract_meta(result) do
    result
    |> String.trim
    |> String.split(": ")
    |> List.last
    |> (&%{ "content_type" => &1 }).()
  end
end
