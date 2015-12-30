defmodule Exfile.Ecto.File do
  @behaviour Ecto.Type

  def type, do: :string

  def cast(%Exfile.File{} = file) do
    if file.backend == backend do
      {:ok, file.id}
    else
      case Exfile.Backend.upload(backend, file) do
        {:ok, new_file} ->
          {:ok, new_file.id}
        {:error, _reason} ->
          :error
      end
    end
  end
  def cast(%Plug.Upload{path: path}) do
    case Exfile.Backend.upload(backend, path) do
      {:ok, new_file} ->
        {:ok, new_file.id}
      {:error, _reason} ->
        :error
    end
  end
  def cast(any) do
    IO.inspect any
    :error
  end

  def load(file_id) when is_binary(file_id) do
    {:ok, Exfile.Backend.get(backend, file_id)}
  end

  def dump(%Exfile.File{} = file), do: {:ok, file.id}
  def dump(file_id) when is_binary(file_id), do: {:ok, file_id}
  def dump(_), do: :error

  defp backend, do: Exfile.Config.backends["store"]
end
