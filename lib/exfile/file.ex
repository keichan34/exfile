defmodule Exfile.File do
  @type file :: map

  defstruct(
    id: nil,
    backend: nil,
    io: nil
  )

  def exists?(file) do
    file.backend.backend_mod.exists?(file.backend, file.id)
  end

  @spec download(file) :: {:ok, file} | {:error, :file.posix}
  def download(file) do
    mod = file.backend.backend_mod
    case mod.open(file.backend, file.id) do
      {:ok, io} ->
        {:ok, %{file | io: io}}
      error ->
        error
    end
  end
end
