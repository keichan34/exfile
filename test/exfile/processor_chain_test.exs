defmodule Exfile.ProcessorChainTest do
  use ExUnit.Case, async: true

  alias Exfile.{ProcessorChain, LocalFile}

  setup do
    string = "hello there, how are you? あおえう"
    {:ok, io} = File.open(string, [:ram, :binary, :read])
    file = %LocalFile{io: io}

    {:ok, %{local_file: file}}
  end

  test "it works", %{local_file: file} do
    processors = [
      "reverse",
      {"truncate", ["6"]}
    ]

    {:ok, out} = ProcessorChain.apply_processors(processors, file)

    {:ok, f} = LocalFile.open(out)
    everything = IO.binread(f, :all) |> IO.chardata_to_string

    assert everything == "うえおあ ?"
  end

  test "halts a chain when an error occurs", %{local_file: file} do
    processors = [
      {"error", [], [error: :hello]},
      {"error", [], [error: :not_reached]},
      {"truncate", ["6"]}
    ]

    out = ProcessorChain.apply_processors(processors, file)

    assert {:error, :hello} == out
  end
end
