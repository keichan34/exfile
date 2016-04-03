defmodule Exfile.Identify do
  def mime_type(path) do
    case System.cmd(file_cmd, ["--mime-type", "-b", path]) do
      {out, 0} ->
        extract_content_type_from_file_output(out)
      {_, _} ->
        :error
    end
  end

  defp extract_content_type_from_file_output(out) do
    out = String.strip(out)
    if Regex.match?(~r{^[-\w]+/[-\w]+$}, out) do
      {:ok, out}
    else
      :error
    end
  end

  defp file_cmd,
    do: :os.find_executable('file') |> IO.chardata_to_string
end
