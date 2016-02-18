defmodule Exfile.Backend.FileSystem do
  use Exfile.Backend

  alias Exfile.LocalFile

  @read_buffer 2048

  def init(opts) do
    {:ok, backend} = super(opts)
    case File.mkdir_p(backend.directory) do
      :ok ->
        backend
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get(backend, id) do
    file = super(backend, id)
    %{file | backend_meta: %{
      absolute_path: path(backend, id)
    }}
  end

  def upload(backend, %Exfile.File{backend: other_backend} = other_file) when backend == other_backend do
    id = backend.hasher.hash(other_file)
    case File.copy(other_file.backend_meta.absolute_path, path(backend, id)) do
      {:ok, _} ->
        {:ok, get(backend, id)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(backend, %Exfile.File{} = other_file) do
    case Exfile.Backend.open(other_file) do
      {:ok, local_file} ->
        upload(backend, local_file)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(backend, %LocalFile{} = local_file) do
    id = backend.hasher.hash(local_file)
    %LocalFile{path: path} = LocalFile.copy_to_tempfile(local_file)
    File.copy!(path, path(backend, id))
    {:ok, get(backend, id)}
  end

  def delete(backend, id) do
    if exists?(backend, id) do
      File.rm(path(backend, id))
    else
      {:error, :enoent}
    end
  end

  def open(backend, id) do
    if exists?(backend, id) do
      {:ok, %LocalFile{path: path(backend, id)}}
    else
      {:error, :enoent}
    end
  end

  def size(backend, id) do
    case File.stat(path(backend, id)) do
      {:ok, %{size: size}} ->
        {:ok, size}
      error ->
        error
    end
  end

  def exists?(backend, id) do
    File.exists?(path(backend, id))
  end
end
