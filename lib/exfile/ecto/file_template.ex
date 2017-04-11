defmodule Exfile.Ecto.FileTemplate do
  @moduledoc """
  A module to help you define an `Ecto.Type` backed by a custom backend.

  Example:

  ```
  defmodule MyApp.User.ProfilePicture do
    use Exfile.Ecto.File,
      backend: "profile_pictures",
      cache_backend: "cache"
  end
  ```

  ```
  defmodule MyApp.User do
    use Ecto.Schema

    schema "users" do
      field :profile_picture, MyApp.User.ProfilePicture
    end
  end
  ```

  This will store any files assigned to the `profile_picture` field of `MyApp.User`
  in the `cache` backend.
  """

  @doc false
  defmacro __using__(opts) do
    backend_name = Keyword.get(opts, :backend, "store")
    cache_backend_name = Keyword.get(opts, :cache_backend, "cache")
    quote do
      @moduledoc """
      An `Ecto.Type` used to handle files persisted to the
      `#{unquote(backend_name)}` backend.
      """

      @behaviour Ecto.Type

      defp backend(), do: Exfile.Config.get_backend(unquote(backend_name))
      defp cache_backend(), do: Exfile.Config.get_backend(unquote(cache_backend_name))

      @doc "The Ecto type"
      def type, do: :string

      @doc """
      Casts a recognizable value to an `%Exfile.File{}` and uploads it to the
      `#{unquote(cache_backend_name)}` backend.

      Accepts five patterns:

      * An `%Exfile.File{}` stored in the `#{unquote(cache_backend_name)}` or `#{unquote(backend_name)}` backends
      * An `%Exfile.File{}` stored in a different backend
      * An `%Exfile.LocalFile{}`
      * A `%Plug.Upload{}`
      * A string URI representing a file from an arbitrary backend

      The string URI can be used to upload a file that is currently stored in
      a separate backend. The format is:

      ```
      exfile://[backend name]/[file ID]
      ```
      """
      def cast(%Exfile.File{backend: %{backend_name: name}} = file) when not name in [unquote(backend_name), unquote(cache_backend_name)] do
        case Exfile.Backend.upload(cache_backend(), file) do
          {:ok, new_file} ->
            {:ok, new_file}
          {:error, _reason} ->
            :error
        end
      end
      def cast(%Exfile.File{} = file), do: {:ok, file}
      def cast(%Plug.Upload{path: path, filename: filename}) do
        cast(%Exfile.LocalFile{
          path: path,
          meta: %{
            "filename" => filename
          }
        })
      end
      def cast(%Exfile.LocalFile{} = local_file) do
        case Exfile.Backend.upload(cache_backend(), local_file) do
          {:ok, new_file} ->
            meta = Map.merge(new_file.meta, local_file.meta)
            new_file = %{ new_file | meta: meta }
            {:ok, new_file}
          {:error, _reason} ->
            :error
        end
      end
      def cast(%URI{scheme: "exfile", host: remote_backend_name, path: "/" <> file_id}) do
        case Exfile.Config.get_backend(remote_backend_name) do
          {:error, _} -> :error
          backend ->
            cast(Exfile.Backend.get(backend, file_id))
        end
      end
      def cast(uri) when is_binary(uri), do: URI.parse(uri) |> cast()
      def cast(_), do: :error

      @doc """
      Loads a file URI from the database and returns an `%Exfile.File{}` struct
      representing that file.

      Supports loading a plain ID for backwards compatibility.
      """
      def load("exfile://" <> _ = file_uri), do: URI.parse(file_uri) |> load
      def load(file_id) when is_binary(file_id) do
        load(%URI{
          scheme: "exfile",
          host: unquote(backend_name),
          path: "/" <> file_id
        })
      end
      def load(%URI{scheme: "exfile", host: remote_backend_name, path: "/" <> file_id}) do
        case Exfile.Config.get_backend(remote_backend_name) do
          {:error, _} -> :error
          backend ->
            {:ok, Exfile.Backend.get(backend, file_id)}
        end
      end

      @doc """
      Dumps an `%Exfile.File{}` struct to the file URI, suitable for storage in
      the database.
      """
      def dump(%Exfile.File{} = file), do: {:ok, Exfile.File.uri(file)}
      def dump(_), do: :error

      @doc """
      Uploads a file from the `#{unquote(cache_backend_name)}` backend to the
      `#{unquote(backend_name)}` backend.

      This function should be called after the record has been successfully saved
      to the database and all validations are passing.
      """
      def upload!(file) do
        Exfile.Backend.upload(backend(), file)
      end
    end
  end
end
