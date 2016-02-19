defmodule Exfile.TokenTest do
  use ExUnit.Case, async: true
  doctest Exfile.Token

  alias Exfile.Token

  test "generate_token generates a valid token" do
    assert Token.generate_token("hello") == "Ag34nHQXujsykyMG7fkivQqLbv7YI2KlHmfvoZxcqrY="
  end

  test "build_path generates a valid path with token embedded" do
    assert Token.build_path("hello") == "Ag34nHQXujsykyMG7fkivQqLbv7YI2KlHmfvoZxcqrY=/hello"
  end

  test "verify_token returns true on valid token" do
    assert Token.verify_token("hello", "Ag34nHQXujsykyMG7fkivQqLbv7YI2KlHmfvoZxcqrY=") == true
  end

  test "verify_token returns false on token mismatch" do
    assert Token.verify_token("hello there", "Ag34nHQXujsykyMG7fkivQqLbv7YI2KlHmfvoZxcqrY=") == false
  end

  test "verify_token returns false on malformed token" do
    assert Token.verify_token("hello", "malformed token!") == false
  end
end
