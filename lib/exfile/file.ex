defmodule Exfile.File do
  defstruct(
    id: nil,
    backend: nil,
    io: nil
  )

  @type file :: %Exfile.File{}

  def exists?(file) do
    Exfile.Backend.exists?(file.backend, file.id)
  end

  @spec download(file) :: {:ok, file} | {:error, :file.posix}
  def download(%Exfile.File{io: nil} = file) do
    case Exfile.Backend.open(file.backend, file.id) do
      {:ok, io} ->
        {:ok, %{file | io: io}}
      error ->
        error
    end
  end

  # Pass-through for a File struct that has an io
  def download(file), do: {:ok, file}
end
