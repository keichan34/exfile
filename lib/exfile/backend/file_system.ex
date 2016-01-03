defmodule Exfile.Backend.FileSystem do
  use Exfile.Backend

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
      {:ok, io} ->
        upload(backend, io)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(backend, io) when is_pid(io) do
    id = backend.hasher.hash(io)
    {:ok, true} = File.open path(backend, id), [:write, :binary], fn(f) ->
      Enum.into(
        IO.binstream(io, @read_buffer),
        IO.binstream(f, @read_buffer)
      )
      true
    end
    {:ok, get(backend, id)}
  end

  def upload(backend, uploadable) when is_binary(uploadable) do
    case File.open(uploadable, [:read, :binary], fn(f) -> upload(backend, f) end) do
      {:ok, result} ->
        result
      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(backend, id) do
    if exists?(backend, id) do
      File.rm(path(backend, id))
    else
      {:error, :enoent}
    end
  end

  def open(backend, id) do
    File.open(path(backend, id), [:read, :binary])
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
