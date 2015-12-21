defmodule Exfile.Backend do
  @moduledoc """

  """

  defstruct(
    backend_mod: nil,
    directory: "",
    max_size: nil,
    hasher: nil
  )

  @type backend :: map
  @type file_id :: String.t
  @type uploadable :: :file.io_device

  @callback init(map) :: {:ok, backend} | {:error, atom}

  @callback upload(backend, uploadable) :: {:ok, Exfile.File.t} | {:error, atom}
  @callback get(backend, String.t) :: Exfile.File.t

  @callback delete(backend, file_id) :: :ok | {:error, :file.posix}
  @callback open(backend, file_id) :: {:ok, :file.io_device} | {:error, :file.posix}
  @callback size(backend, file_id) :: {:ok, pos_integer} | {:error, :file.posix}
  @callback exists?(backend, file_id) :: boolean
  @callback path(backend, file_id) :: Path.t

  defmacro __using__(_) do
    quote do
      def init(opts) do
        {:ok, %Exfile.Backend{
          backend_mod: __MODULE__,
          directory: opts.directory,
          max_size: opts.max_size,
          hasher: opts.hasher
        }}
      end

      def get(backend, id) do
        %Exfile.File{backend: backend, id: id}
      end

      def clear!(backend) do
        {:error, :notimpl}
      end

      defoverridable [init: 1]
      defoverridable [get: 2]
      defoverridable [clear!: 1]
    end
  end
end
