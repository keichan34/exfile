defmodule Exfile.File do
  defstruct(
    id: nil,
    backend: nil,
    backend_meta: %{}
  )

  @type file :: %Exfile.File{}

  @spec exists?(file) :: true | false
  def exists?(file) do
    Exfile.Backend.exists?(file.backend, file.id)
  end

  @spec download(file) :: {:ok, pid} | {:error, :file.posix}
  def download(file) do
    Exfile.Backend.open(file.backend, file.id)
  end
end
