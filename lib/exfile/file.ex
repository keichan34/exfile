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

  @doc """
  Deletes a file.
  """
  @spec delete(file) :: :ok | {:error, :file.posix}
  def delete(file) do
    Exfile.Backend.delete(file.backend, file.id)
  end

  @doc """
  Opens a file.
  """
  @spec open(file) :: {:ok, %Exfile.LocalFile{}} | {:error, :file.posix}
  def open(file) do
    Exfile.Backend.open(file.backend, file.id)
  end

  @doc """
  Returns the size, in bytes, of an Exfile.File.
  """
  @spec size(file) :: {:ok, pos_integer} | {:error, :file.posix}
  def size(file) do
    Exfile.Backend.size(file.backend, file.id)
  end

  @doc """
  Checks if the file given actually exists in the backend or not.
  """
  @spec exists?(file) :: boolean
  def exists?(file) do
    Exfile.Backend.exists?(file.backend, file.id)
  end
end

defimpl Phoenix.HTML.Safe, for: Exfile.File do
  def to_iodata(%Exfile.File{id: id}), do: id
end
