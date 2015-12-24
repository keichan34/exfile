defmodule Exfile.BackendTest do
  @moduledoc """
  Shared tests for your backends.

  Usage:

      use Exfile.BackendTest, [MyBackend, %{backend options}]

  """

  @doc false
  defmacro __using__([backend_mod_to_test, opts]) do
    quote do
      use ExUnit.Case, async: true

      def backend_mod, do: unquote(backend_mod_to_test)

      import Exfile.BackendTest

      setup do
        backend = backend_mod.init(unquote(opts))
        {:ok, [backend: backend]}
      end

      test "backend was instantitated", c do
        refute match?({:error, _}, c[:backend])
      end

      test "exists? returns false for a non-existant ID", c do
        refute backend_mod.exists?(c[:backend], "nonexistant-id")
      end

      test "can upload a file and get it back", c do
        string = "hello there"
        {:ok, file} = upload_string(c[:backend], string)

        assert backend_mod.exists?(c[:backend], file.id)

        {:ok, open_file} = backend_mod.open(c[:backend], file.id)
        assert IO.read(open_file, :all) == string
      end

      test "can upload a file, delete it, and not get it back", c do
        string = "hello there"
        {:ok, file} = upload_string(c[:backend], string)

        assert backend_mod.exists?(c[:backend], file.id)
        assert :ok = backend_mod.delete(c[:backend], file.id)
        refute backend_mod.exists?(c[:backend], file.id)
        assert {:error, _} = backend_mod.open(c[:backend], file.id)
      end

      test "returns the correct size", c do
        string = "hello there"
        {:ok, file} = upload_string(c[:backend], string)

        {:ok, size_from_backend} = backend_mod.size(c[:backend], file.id)
        assert size_from_backend == String.length(string)
      end
    end
  end

  def upload_string(backend, string) do
    {:ok, uploadable} = StringIO.open(string)
    backend.backend_mod.upload(backend, uploadable)
  end
end
