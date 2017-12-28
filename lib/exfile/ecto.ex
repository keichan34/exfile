if Code.ensure_loaded?(Ecto) do

defmodule Exfile.Ecto do
  alias Ecto.Changeset

  @doc """
  Prepares Exfile fields to be uploaded before the data is saved to database.
  Takes a changeset and a list of Exfile fields to prepare the upload on.

  Uses `Ecto.Changeset.prepare_changes/2` to upload the files.

  If a file fails to upload, an exception is thrown and the transaction fails.

  For example, in the following code segment,

      {:ok, image} = Image.changeset(%Image{}, image_params)
        |> Exfile.Ecto.prepare_uploads([:image])
        |> Repo.insert

  the `image` field is defined in the schema of the `Image` module. Calling
  `Exfile.Ecto.prepare_uploads` with a list of the Exfile fields will prepare
  them to be uploaded. Note that if the changeset is not valid, the files will
  not be uploaded.
  """
  def prepare_uploads(changeset, fields) do
    Changeset.prepare_changes(changeset, fn changeset ->
      perform_uploads!(changeset, fields)
    end)
  end

  defp perform_uploads!(changeset, fields) do
    Enum.reduce fields, changeset, fn (field, changeset) ->
      perform_upload!(changeset, field)
    end
  end

  defp perform_upload!(changeset, field) do
    with {:ok, t} <- ecto_type_for_field(changeset.data, field),
      file when not is_nil(file) <- Changeset.get_field(changeset, field),
      {:ok, uploaded_file} <- t.upload!(file)
    do
      Changeset.put_change(changeset, field, uploaded_file)
    else
      nil -> #happens if an exfile field is optional and thus might not be set
        changeset
      error ->
        throw error
    end

  end

  defp ecto_type_for_field(%{__struct__: mod}, field) do
    {:ok, mod.__schema__(:type, field)}
  end
end

end
