defmodule Exfile.Backend.FileSystem do
  @moduledoc """
  A local filesystem-backed backend.

  FileSystem accepts the standard initialization options, plus one:

  * `:ttl` -- configurable TTL (in seconds) for files stored in the backend.
    Files are checked and vacuumed on initialization or by calling `vacuum/1`
    manually. Note that the mtime (file modification timestamp) is used to
    determine if a file should be deleted or not. This option only makes sense
    in an ephemeral cache configuration, never a persistent store.
  """

  use Exfile.Backend

  alias Exfile.LocalFile

  def init(opts) do
    {:ok, backend} = super(opts)
    ttl = Keyword.get(opts, :ttl, :infinity)
    backend = backend
    |> Exfile.Backend.put_meta(:ttl, ttl)

    with  :ok <- File.mkdir_p(backend.directory),
          :ok <- vacuum(backend),
          do: backend
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

  def upload(backend, file, monitor_pid \\ nil)

  def upload(backend, %Exfile.File{} = other_file, _monitor_pid) do
    case Exfile.File.open(other_file) do
      {:ok, local_file} ->
        upload(backend, local_file)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(backend, %LocalFile{} = local_file, monitor_pid) do
    id = backend.hasher.hash(local_file)
    %LocalFile{path: path} = LocalFile.copy_to_tempfile(local_file, monitor_pid)
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

  @doc """
  Scan & delete files in backend that have expired

  No-op when the `:ttl` option is "infinity" or nil (default).
  """
  @spec vacuum(Exfile.Backend.t) :: :ok | {:error, :file.posix}
  def vacuum(backend)
  def vacuum(%{meta: %{ttl: ttl}}) when ttl in [nil, :infinity], do: :ok
  def vacuum(%{directory: dir, meta: %{ttl: ttl}}) when is_integer(ttl) do
    now = :os.system_time(:seconds)
    with  {:ok, files} <- File.ls(dir),
          do: perform_vacuum(dir, ttl, now, files)
  end

  defp perform_vacuum(_,   _,   _,   []), do: :ok
  defp perform_vacuum(_,   _,   _,   {:error, _} = error), do: error
  defp perform_vacuum(dir, ttl, now, [file | files]) do
    file_abspath = Path.join(dir, file)
    files_or_error = case File.stat(file_abspath, time: :posix) do
      {:ok, %File.Stat{mtime: time}} when (time + ttl) < now ->
        # perform delete
        with :ok <- File.rm(file_abspath), do: files
      {:ok, _} -> files
      error -> error
    end
    perform_vacuum(dir, ttl, now, files_or_error)
  end
end
