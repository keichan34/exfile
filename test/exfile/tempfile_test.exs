# This module is a derivative of Plug.UploadTest under the Apache 2.0 license.
# The current form was adapted from https://raw.githubusercontent.com/elixir-lang/plug/57e9a1df01f4ef57a01d58b6eb2247df7f910286/test/plug/upload_test.exs

defmodule Exfile.TempfileTest do
  use ExUnit.Case, async: true

  test "removes the random file on process death" do
    parent = self()

    {pid, ref} = spawn_monitor fn ->
      {:ok, path} = Exfile.Tempfile.random_file("sample")
      send parent, {:path, path}
      File.open!(path)
    end

    path =
      receive do
        {:path, path} -> path
      after
        1_000 -> flunk "didn't get a path"
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        {:ok, _} = Exfile.Tempfile.random_file("sample")
        refute File.exists?(path)
    end
  end

  test "removes a random file that was moved on process death" do
    parent = self()

    {pid, ref} = spawn_monitor fn ->
      {:ok, path} = Exfile.Tempfile.random_file("sample")
      File.open!(path)
      new_path = Path.join(Path.dirname(path), "new-sample")
      File.rename(path, new_path)
      Exfile.Tempfile.register_file(new_path)
      send parent, {:path, new_path}
      File.open!(new_path)
    end

    path =
      receive do
        {:path, path} -> path
      after
        1_000 -> flunk "didn't get a path"
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} ->
        {:ok, _} = Exfile.Tempfile.random_file("sample")
        refute File.exists?(path)
    end
  end
end
