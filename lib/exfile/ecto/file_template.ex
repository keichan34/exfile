defmodule Exfile.Ecto.FileTemplate do
  @moduledoc """
  A module to help you define an `Ecto.Type` backed by a custom backend.

  Example:

  ```
  defmodule MyApp.User.ProfilePicture do
    use Exfile.Ecto.File, backend: "profile_pictures"
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
  in the backend configured as "profile_pictures".
  """

  @doc false
  defmacro __using__(opts) do
    backend_name = Keyword.get(opts, :backend, "store")
    quote do
      @moduledoc """
      An `Ecto.Type` used to handle files persisted to the
      `#{unquote(backend_name)}` backend.
      """

      @behaviour Ecto.Type

      defp backend, do: Exfile.Config.get_backend(unquote(backend_name))

      @doc "The Ecto type"
      def type, do: :string

      @doc """
      Casts a recognizable value to an `%Exfile.File{}` and uploads it to the
      backend if necessary.

      Accepts four patterns:

      * Another `%Exfile.File{}`
      * An `%Exfile.LocalFile{}`
      * A `%Plug.Upload{}`
      * A string URI representing a file from an arbitrary backend

      The string URI can be used to upload a file that is currently stored in
      a separate backend. The format is:

      ```
      exfile://[backend name]/[file ID]
      ```
      """
      def cast(%Exfile.File{} = file) do
        case Exfile.Backend.upload(backend, file) do
          {:ok, new_file} ->
            {:ok, new_file}
          {:error, _reason} ->
            :error
        end
      end
      def cast(%Plug.Upload{path: path}) do
        cast(%Exfile.LocalFile{path: path})
      end
      def cast(%Exfile.LocalFile{} = local_file) do
        case Exfile.Backend.upload(backend, local_file) do
          {:ok, new_file} ->
            {:ok, new_file}
          {:error, _reason} ->
            :error
        end
      end
      def cast(%URI{scheme: "exfile", host: unquote(backend_name), path: "/" <> file_id}) do
        {:ok, %Exfile.File{
          id: file_id,
          backend: backend
        }}
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
      Loads a file ID from the database and returns an `%Exfile.File{}` struct
      representing that file.
      """
      def load(file_id) when is_binary(file_id),
        do: {:ok, Exfile.Backend.get(backend, file_id)}

      @doc """
      Dumps an `%Exfile.File{}` struct to the file ID, suitable for storage in
      the database.
      """
      def dump(%Exfile.File{} = file), do: {:ok, file.id}
      def dump(_), do: :error
    end
  end
end
