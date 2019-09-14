defmodule Exfile.LocalFile do
  @moduledoc """
  Represents a file on the local filesystem.
  """

  alias Exfile.LocalFile, as: LF

  defmacrop not_nil(term) do
    quote do
      not is_nil(unquote(term))
    end
  end

  defstruct(
    path: nil,
    io: nil,
    meta: %{}
  )

  @type t :: %LF{path: String.t, io: :file.io_device, meta: map}

  @read_buffer 2048

  @spec put_meta(t, atom, any) :: t
  def put_meta(file, key, value) do
    put_in(file.meta[key], value)
  end

  @doc """
  Opens a LocalFile into an IO pid.

  If the LocalFile is already IO-based, the IO will be rewound to the beginning
  of the file.
  """
  @spec open(t) :: {:ok, :file.io_device} | {:error, :file.posix} | no_return
  def open(%LF{io: nil, path: path}) when not_nil(path) do
    File.open(path, [:read, :binary])
  end
  def open(%LF{io: io, path: nil}) when not_nil(io) do
    {:ok, _} = :file.position(io, :bof)
    {:ok, io}
  end
  def open(%LF{io: io, path: path}) when not_nil(io) and not_nil(path) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, not both."
  end
  def open(%LF{io: nil, path: nil}) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, but you gave me one with neither."
  end

  @doc """
  Copies the LocalFile to a new file-based LocalFile.

  Once the calling pid dies, the file will be automatically removed from the
  filesystem (see Exfile.Tempfile for more details).
  """
  @spec copy_to_tempfile(t, pid() | nil) :: t | no_return
  def copy_to_tempfile(file, monitor_pid \\ nil)

  def copy_to_tempfile(%LF{path: path, meta: meta}, monitor_pid) when not_nil(path) do
    temp = Exfile.Tempfile.random_file!("exfile-file", monitor_pid)
    {:ok, _} = File.copy(path, temp)
    %LF{path: temp, meta: meta}
  end
  def copy_to_tempfile(%LF{io: io, meta: meta}, monitor_pid) when not_nil(io) do
    temp = Exfile.Tempfile.random_file!("exfile-file", monitor_pid)
    {:ok, true} = File.open temp, [:write, :binary], fn(f) ->
      Enum.into(
        IO.binstream(io, @read_buffer),
        IO.binstream(f, @read_buffer)
      )
      true
    end
    %LF{path: temp, meta: meta}
  end
  def copy_to_tempfile(%LF{io: io, path: path}, _monitor_pid) when not_nil(io) and not_nil(path) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, not both."
  end
  def copy_to_tempfile(%LF{io: nil, path: nil}, _monitor_pid) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, but you gave me one with neither."
  end

  @doc """
  Returns the size (in bytes) of the file.
  """
  @spec size(t) :: {:ok, integer} | {:error, :file.posix}
  def size(%LF{path: path}) when not_nil(path) do
    case File.stat(path) do
      {:ok, %{size: size}} -> {:ok, size}
      error -> error
    end
  end

  def size(%LF{io: io}) when not_nil(io) do
    stream = IO.binstream(io, 1)
    size = Enum.count(stream)
    _ = :file.position(io, :bof)
    {:ok, size}
  end
end
