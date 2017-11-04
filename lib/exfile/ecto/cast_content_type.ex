if Code.ensure_loaded?(Ecto) do

defmodule Exfile.Ecto.CastContentType do
  alias Ecto.Changeset
  alias Exfile.Processor.ContentType, as: ContentTypeProcessor

  def cast_content_type(changeset, field) when is_atom(field) do
    cast_content_type(changeset, field, String.to_atom("#{field}_content_type"))
  end
  def cast_content_type(changeset, field, content_type_field) when is_atom(content_type_field) do
    case Changeset.get_change(changeset, field) do
      %Exfile.File{} -> perform_cast(changeset, field, content_type_field)
      _              -> changeset
    end
  end

  defp perform_cast(changeset, field, content_type_field) do
    changeset
    |> Changeset.get_change(field)
    |> ContentTypeProcessor.call([], [])
    |> case do
      { :ok, processed_file } ->
        changeset
        |> Changeset.put_change(content_type_field, processed_file.meta["content_type"])
      _ -> changeset
    end
  end
end

end
