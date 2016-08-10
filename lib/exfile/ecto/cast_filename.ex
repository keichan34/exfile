if Code.ensure_loaded?(Ecto) do

defmodule Exfile.Ecto.CastFilename do
  alias Ecto.Changeset

  def cast_filename(changeset, field) when is_atom(field) do
    cast_filename(changeset, field, String.to_atom("#{field}_filename"))
  end
  def cast_filename(changeset, field, filename_field) when is_atom(filename_field) do
    changeset
    |> Changeset.get_change(field)
    |> case do
      nil -> changeset
      file ->
        Changeset.put_change(changeset, filename_field, file.meta["filename"])
    end
  end
end

end
