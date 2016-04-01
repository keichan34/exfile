defmodule Exfile.ConfigTest do
  use ExUnit.Case, async: true

  test "get_backend/1 with an invalid backend name works" do
    assert_raise RuntimeError, "The backend aoeu couldn't be initialized: backend_not_found", fn ->
      Exfile.Config.get_backend("aoeu")
    end
  end
end
