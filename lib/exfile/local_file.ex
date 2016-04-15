defmodule Exfile.LocalFile do
  @moduledoc """
  Represents a file either on the local filesystem or in memory.
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

  def put_meta(file, key, value) do
    put_in(file.meta[key], value)
  end

  @doc """
  Opens a LocalFile into an IO pid. If the LocalFile is already IO-based, the
  IO will be rewound to the beginning of the file.
  """
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
  Copies the LocalFile to a new file-based LocalFile. Once the calling pid dies,
  the file will be automatically removed from the filesystem (see
  Exfile.Tempfile for more details).
  """
  def copy_to_tempfile(%LF{path: path, meta: meta}) when not_nil(path) do
    temp = Exfile.Tempfile.random_file!("exfile-file")
    {:ok, _} = File.copy(path, temp)
    %LF{path: temp, meta: meta}
  end
  def copy_to_tempfile(%LF{io: io, meta: meta}) when not_nil(io) do
    temp = Exfile.Tempfile.random_file!("exfile-file")
    {:ok, true} = File.open temp, [:write, :binary], fn(f) ->
      Enum.into(
        IO.binstream(io, @read_buffer),
        IO.binstream(f, @read_buffer)
      )
      true
    end
    %LF{path: temp, meta: meta}
  end
  def copy_to_tempfile(%LF{io: io, path: path}) when not_nil(io) and not_nil(path) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, not both."
  end
  def copy_to_tempfile(%LF{io: nil, path: nil}) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, but you gave me one with neither."
  end
end
