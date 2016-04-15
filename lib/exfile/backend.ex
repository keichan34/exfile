defmodule Exfile.Backend do
  @moduledoc """
  Represents a backend that stores files.
  """

  defstruct(
    backend_mod: nil,
    backend_name: nil,
    directory: "",
    max_size: nil,
    hasher: nil,
    preprocessors: [],
    postprocessors: [],
    meta: %{}
  )

  @type t :: %Exfile.Backend{}

  @type backend :: t
  @type file_id :: String.t
  @type uploadable :: Exfile.File.t | Exfile.LocalFile.t

  @callback init(map) :: backend | {:error, atom}

  @doc """
  upload/2 must handle at least two cases of `uploadable`:

  1. an %Exfile.File{}
  2. an %Exfile.LocalFile{}

  You may elect to implement a third case that handles uploading between
  identical backends, if there is a more efficient way to implement it.
  See Exfile.Backend.FileSystem.upload/2 for an example.
  """
  @callback upload(backend, uploadable) :: {:ok, Exfile.File.t} | {:error, atom}

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
        {:ok, %Exfile.Backend{
          backend_mod: __MODULE__,
          backend_name: Dict.get(opts, :name),
          directory: Dict.get(opts, :directory, ""),
          max_size: Dict.get(opts, :max_size, nil),
          hasher: Dict.get(opts, :hasher, Exfile.Hasher.Random),
          preprocessors: Dict.get(opts, :preprocessors, []),
          postprocessors: Dict.get(opts, :postprocessors, [])
        }}
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
  @spec upload(backend, uploadable) :: {:ok, Exfile.File.t} | {:error, atom}
  def upload(backend, uploadable) do
    preprocessors = backend.preprocessors
    with  {:ok, process_result} <- ProcessorChain.apply_processors(preprocessors, uploadable),
          do: backend.backend_mod.upload(backend, process_result)
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
