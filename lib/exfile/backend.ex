defmodule Exfile.Backend do
  @moduledoc """
  Represents a backend that stores files.
  """

  defstruct(
    backend_mod: nil,
    backend_name: nil,
    directory: "",
    max_size: -1,
    hasher: Exfile.Hasher.Random,
    preprocessors: [],
    postprocessors: [],
    meta: %{}
  )

  @type t :: %Exfile.Backend{
    backend_mod: atom,
    backend_name: String.t,
    directory: String.t,
    max_size: integer,
    hasher: atom,
    preprocessors: [Exfile.ProcessorChain.definition, ...],
    postprocessors: [Exfile.ProcessorChain.definition, ...],
    meta: map
  }

  @type backend :: t
  @type file_id :: Exfile.File.file_id
  @type uploadable :: Exfile.File.t | Exfile.LocalFile.t
  @type monitor_pid :: pid() | nil

  @callback init([name: String.t]) :: backend | {:error, atom}

  @doc """
  upload/3 must handle at least two cases of `uploadable`:

  1. an %Exfile.File{}
  2. an %Exfile.LocalFile{}

  You may elect to implement a third case that handles uploading between
  identical backends, if there is a more efficient way to implement it.
  See Exfile.Backend.FileSystem.upload/2 for an example.
  """
  @callback upload(backend, uploadable, monitor_pid) :: {:ok, Exfile.File.t} | {:error, atom}

  @doc """
  Construct an Exfile.File struct representing the given file_id.
  """
  @callback get(backend, file_id) :: Exfile.File.t

  @doc """
  Delete a file from the backend, identified by file_id.
  """
  @callback delete(backend, file_id) :: :ok | {:error, :file.posix}

  @doc """
  Open a file from the backend. This function should download the file either to
  a temporary file or to memory in the Exfile.LocalFile struct.
  """
  @callback open(backend, file_id) :: {:ok, Exfile.LocalFile.t} | {:error, :file.posix}

  @doc """
  Get the size of a file from the backend
  """
  @callback size(backend, file_id) :: {:ok, pos_integer} | {:error, :file.posix}

  @callback exists?(backend, file_id) :: boolean
  @callback path(backend, file_id) :: Path.t

  defmacro __using__(_) do
    quote do
      @behaviour Exfile.Backend

      def init(opts) do
        backend = %Exfile.Backend{
          backend_mod: __MODULE__,
          backend_name: Keyword.get(opts, :name)
        }
        {merge_opts, _} = Keyword.split(opts,
          ~w(directory max_size hasher preprocessors postprocessors)a)
        backend = Map.merge(backend, Enum.into(merge_opts, %{}))

        {:ok, backend}
      end

      def get(backend, id) do
        %Exfile.File{backend: backend, id: id}
      end

      def clear!(backend) do
        {:error, :notimpl}
      end

      def path(backend, id) do
        Path.join(backend.directory, id)
      end

      defoverridable [init: 1, get: 2, clear!: 1, path: 2]
    end
  end

  alias Exfile.ProcessorChain

  @doc """
  Uploads a file to the given backend, applying preprocessors if configured.
  """
  @spec upload(backend, uploadable, monitor_pid) :: {:ok, Exfile.File.t} | {:error, atom}
  def upload(backend, uploadable, monitor_pid \\ nil) do
    preprocessors = backend.preprocessors
    with  {:ok, process_result} <- ProcessorChain.apply_processors(preprocessors, uploadable),
          :ok <- verify_file_size(backend, process_result),
          do: backend.backend_mod.upload(backend, process_result, monitor_pid)
  end

  defp verify_file_size(%{max_size: -1}, _), do: :ok
  defp verify_file_size(%{max_size: max_size}, %Exfile.File{} = file) do
    case Exfile.File.size(file) do
      {:ok, size} -> verify_file_size(max_size, size)
      error -> error
    end
  end
  defp verify_file_size(%{max_size: max_size}, %Exfile.LocalFile{} = lf) do
    case Exfile.LocalFile.size(lf) do
      {:ok, size} -> verify_file_size(max_size, size)
      error -> error
    end
  end
  defp verify_file_size(max_size, file_size) when file_size > max_size,
    do: {:error, :too_big}
  defp verify_file_size(_max_size, _file_size),
    do: :ok

  @doc """
  Puts a value in the "meta" section of the backend setting.
  """
  @spec put_meta(backend, any, any) :: backend
  def put_meta(backend, key, value) do
    %{backend | meta: Map.put(backend.meta, key, value)}
  end

  @doc """
  Get the `Exfile.File` struct representing a file on the given backend.

  This function does not open the file or download it. Use open/2 or
  Exfile.File.open/1 to open the file.
  """
  @spec get(backend, file_id) :: Exfile.File.t
  def get(backend, file_id) do
    backend.backend_mod.get(backend, file_id)
  end

  @doc """
  Deletes a file from the given backend by the file ID.
  """
  @spec delete(backend, file_id) :: :ok | {:error, :file.posix}
  def delete(backend, file_id) do
    backend.backend_mod.delete(backend, file_id)
  end

  @doc """
  Opens a file on the given backend, applying postprocessors if configured.
  """
  @spec open(backend, file_id) :: {:ok, Exfile.LocalFile.t} | {:error, :file.posix}
  def open(backend, file_id) do
    postprocessors = backend.postprocessors
    with  {:ok, local_file}     <- backend.backend_mod.open(backend, file_id),
          do: ProcessorChain.apply_processors(postprocessors, local_file)
  end

  @doc """
  A convenience function to call `backend.backend_mod.size(backend, file_id)`
  """
  @spec size(backend, file_id) :: {:ok, pos_integer} | {:error, :file.posix}
  def size(backend, file_id) do
    backend.backend_mod.size(backend, file_id)
  end

  @doc """
  A convenience function to call `backend.backend_mod.exists?(backend, file_id)`
  """
  @spec exists?(backend, file_id) :: boolean
  def exists?(backend, file_id) do
    backend.backend_mod.exists?(backend, file_id)
  end

  @doc """
  A convenience function to call `backend.backend_mod.path(backend, file_id)`
  """
  @spec path(backend, file_id) :: Path.t
  def path(backend, file_id) do
    backend.backend_mod.path(backend, file_id)
  end
end
