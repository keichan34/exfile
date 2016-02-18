defmodule Exfile.File do
  @moduledoc """
  Represents a file stored on a Backend.
  """

  defstruct(
    id: nil,
    meta: %{},
    backend: nil,
    backend_meta: %{}
  )

  @type file :: %Exfile.File{}

  @spec exists?(file) :: true | false
  def exists?(file) do
    Exfile.Backend.exists?(file.backend, file.id)
  end

  @spec download(file) :: {:ok, Exfile.LocalFile.t} | {:error, :file.posix}
  def download(file) do
    Exfile.Backend.open(file.backend, file.id)
  end
end

defimpl Phoenix.HTML.Safe, for: Exfile.File do
  def to_iodata(%Exfile.File{id: id}), do: id
end
