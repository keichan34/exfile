defmodule Exfile.LocalFile do
  alias Exfile.LocalFile, as: LF

  defmacrop is_truthy(term) do
    quote do
      not is_nil(unquote(term))
    end
  end

  defstruct(
    path: nil,
    io: nil,
    meta: %{}
  )

  @read_buffer 2048

  def put_meta(file, key, value) do
    put_in(file.meta[key], value)
  end

  def open(%LF{io: nil, path: path} = file) when is_truthy(path) do
    File.open(path, [:read, :binary])
  end
  def open(%LF{io: io, path: nil}) when is_truthy(io) do
    :file.position(io, :bof)
    {:ok, io}
  end
  def open(%LF{io: io, path: path}) when is_truthy(io) and is_truthy(path) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, not both."
  end
  def open(%LF{io: nil, path: nil}) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, but you gave me one with neither."
  end

  def copy_to_tempfile(%LF{path: path, meta: meta}) when is_truthy(path) do
    temp = Exfile.Tempfile.random_file!("exfile-file")
    {:ok, _} = File.copy(path, temp)
    %LF{path: temp, meta: meta}
  end
  def copy_to_tempfile(%LF{io: io, meta: meta}) when is_truthy(io) do
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
  def copy_to_tempfile(%LF{io: io, path: path}) when is_truthy(io) and is_truthy(path) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, not both."
  end
  def copy_to_tempfile(%LF{io: nil, path: nil}) do
    raise ArgumentError, message: "I expected an Exfile.LocalFile with either an io or a path, but you gave me one with neither."
  end
end
