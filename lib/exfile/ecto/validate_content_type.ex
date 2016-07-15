if Code.ensure_loaded?(Ecto) do

defmodule Exfile.Ecto.ValidateContentType do
  alias Ecto.Changeset
  alias Exfile.Processor.ContentType, as: ContentTypeProcessor

  @registered_types %{
    image: ~w(image/bmp image/gif image/jpeg image/png),
    video: ~w(video/quicktime video/mp4 video/x-msvideo video/x-ms-wmv video/x-flv video/3gpp),
    audio: ~w(audio/mpeg audio/x-wav audio/ogg)
  }

  def validate_content_type(changeset, field, accepted_content_types, message \\ "invalid format") do
    case Changeset.get_change(changeset, field) do
      %Exfile.File{} -> perform_validation(changeset, field, accepted_content_types, message)
      _              -> changeset
    end
  end

  defp perform_validation(changeset, field, accepted_content_types, message) do
    { :ok, processed_file } = changeset
      |> Changeset.get_change(field)
      |> ContentTypeProcessor.call([], [])

    changeset_with_processed_file = changeset
      |> Changeset.put_change(field, processed_file)

    if processed_file.meta["content_type"] in expand_content_types(accepted_content_types) do
      changeset_with_processed_file
    else
      changeset_with_processed_file
      |> Changeset.add_error(field, message)
    end
  end

  defp expand_content_types(content_type) when is_list(content_type), do: content_type
  defp expand_content_types(content_type) when is_atom(content_type) do
    @registered_types[content_type]
  end
end

end
