defmodule Exfile.TokenTest do
  use ExUnit.Case, async: true
  doctest Exfile.Token

  alias Exfile.Token

  setup do
    token = "fdb2bd677b6f67b45086d5f4e74ba655fd1798c1"
    {:ok, [token: token]}
  end

  test "generate_token generates a valid token", %{token: token} do
    assert Token.generate_token("hello") == token
  end

  test "build_path generates a valid path with token embedded", %{token: token} do
    assert Token.build_path("hello") == token <> "/hello"
  end

  test "verify_token returns true on valid token", %{token: token} do
    assert Token.verify_token("hello", token)
  end

  test "verify_token returns false on token mismatch", %{token: token} do
    refute Token.verify_token("hello there", token)
  end

  test "verify_token returns false on malformed token" do
    refute Token.verify_token("hello", "malformed token!")
  end
end
