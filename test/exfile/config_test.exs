defmodule Exfile.ConfigTest do
  use ExUnit.Case, async: false

  test "get_backend/1 with an invalid backend name works" do
    assert_raise RuntimeError, "The backend aoeu couldn't be initialized: backend_not_found", fn ->
      Exfile.Config.get_backend("aoeu")
    end
  end

  test "refresh_backend_config/0 works" do
    assert %Exfile.Backend{
      backend_mod: Exfile.Backend.FileSystem
    } = Exfile.Config.get_backend("store")

    Exfile.Config.refresh_backend_config

    assert %Exfile.Backend{
      backend_mod: Exfile.Backend.FileSystem
    } = Exfile.Config.get_backend("store")
  end
end
