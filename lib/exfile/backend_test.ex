defmodule Exfile.BackendTest do
  @moduledoc """
  Shared tests for your backends.

  Usage:

      defmodule MyBackendTest do
        use Exfile.BackendTest, [MyBackend, %{backend options}]
      end
  """

  @doc false
  defmacro __using__([backend_mod_to_test, opts]) do
    quote do
      use ExUnit.Case, async: true

      alias Exfile.Backend
      alias Exfile.LocalFile

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
        refute Backend.exists?(c[:backend], "nonexistant-id")
      end

      test "can upload a file and get it back", c do
        string = "hello there"
        {:ok, file} = upload_string(c[:backend], string)

        assert Backend.exists?(c[:backend], file.id)

        {:ok, local_file} = Backend.open(c[:backend], file.id)
        {:ok, open_file} = LocalFile.open(local_file)
        assert IO.binread(open_file, :all) == string
      end

      test "can upload a file, delete it, and not get it back", c do
        string = "hello there"
        {:ok, file} = upload_string(c[:backend], string)

        assert Backend.exists?(c[:backend], file.id)
        assert :ok = Backend.delete(c[:backend], file.id)
        refute Backend.exists?(c[:backend], file.id)
        assert {:error, _} = Backend.open(c[:backend], file.id)
      end

      test "returns the correct size", c do
        string = "hello there"
        {:ok, file} = upload_string(c[:backend], string)

        {:ok, size_from_backend} = Backend.size(c[:backend], file.id)
        assert size_from_backend == String.length(string)
      end
    end
  end

  alias Exfile.LocalFile

  def upload_string(backend, string) do
    {:ok, io} = File.open(string, [:ram, :binary])
    Exfile.Backend.upload(backend, %LocalFile{io: io})
  end
end
