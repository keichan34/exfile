defmodule Exfile.Hasher.RandomTest do
  use ExUnit.Case, async: true

  @hasher Exfile.Hasher.Random

  test "returns a random ID" do
    assert String.length(@hasher.hash(nil)) == 60
    refute @hasher.hash(nil) == @hasher.hash(nil)
  end
end
