defmodule Exfile.ProcessorTest do
  use ExUnit.Case, async: true

  @string_1 "hello there, how are you? あおえう"

  alias Exfile.LocalFile

  setup do
    {:ok, io} = File.open(@string_1, [:ram, :binary, :read])

    {:ok, %{
      local_file: %LocalFile{io: io}
    }}
  end

  test "simple processing", %{local_file: file} do
    {:ok, out} = Exfile.ProcessorRegistry.process("reverse", file, [])

    {:ok, f} = LocalFile.open(out)
    everything = IO.binread(f, :all) |> IO.chardata_to_string
    assert everything == String.reverse(@string_1)
  end

  test "chained processing", %{local_file: file} do
    {:ok, out} = Exfile.ProcessorRegistry.process("reverse", file, [])
    {:ok, out} = Exfile.ProcessorRegistry.process("reverse", out, [])

    {:ok, f} = LocalFile.open(out)
    everything = IO.binread(f, :all) |> IO.chardata_to_string
    assert everything == @string_1
  end
end
