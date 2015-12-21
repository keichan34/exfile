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

  def upload(backend, uploadable) do
    id = backend.hasher.hash(uploadable)
    {:ok, f} = File.open path(backend, id), [:write, :binary]
    Enum.into(IO.binstream(uploadable, @read_buffer), IO.binstream(f, @read_buffer))
    File.close(f)
    %Exfile.File{backend: backend, id: id}
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

  def path(backend, id) do
    Path.join(backend.directory, id)
  end
end
