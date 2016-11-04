if Code.ensure_loaded?(Ecto) do

defmodule Exfile.Ecto.ValidateFileSize do
  alias Ecto.Changeset
  alias Exfile.Processor.FileSize, as: FileSizeProcessor

  def validate_file_size(changeset, field, maximum_file_size, message \\ "file size is too big")
    when is_integer(maximum_file_size) do
    case Changeset.get_change(changeset, field) do
      %Exfile.File{} -> perform_validation(changeset, field, maximum_file_size, message)
      _              -> changeset
    end
  end

  defp perform_validation(changeset, field, maximum_file_size, message) do
    { :ok, processed_file } = changeset
      |> Changeset.get_change(field)
      |> FileSizeProcessor.call([], [])

    changeset_with_processed_file = changeset
      |> Changeset.put_change(field, processed_file)

    if processed_file.meta["file_size"] <= maximum_file_size do
      changeset_with_processed_file
    else
      changeset_with_processed_file
      |> Changeset.add_error(field, message)
    end
  end
end

end
