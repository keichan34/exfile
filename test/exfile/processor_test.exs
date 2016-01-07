defmodule Exfile.ProcessorTest do
  use ExUnit.Case, async: true

  @string_1 "hello there, how are you? あおえう"

  setup do
    {:ok, io} = File.open(@string_1, [:ram, :binary, :read])

    {:ok, %{
      io: io
    }}
  end

  test "simple processing", %{io: io} do
    {:ok, {:io, out}} = Exfile.ProcessorRegistry.process("reverse", {:io, io}, [])
    everything = IO.binread(out, :all) |> IO.chardata_to_string
    assert everything == String.reverse(@string_1)
  end

  test "chained processing", %{io: io} do
    {:ok, out} = Exfile.ProcessorRegistry.process("reverse", {:io, io}, [])
    {:ok, {:io, outio}} = Exfile.ProcessorRegistry.process("reverse", out, [])
    everything = IO.binread(outio, :all) |> IO.chardata_to_string
    assert everything == @string_1
  end
end
