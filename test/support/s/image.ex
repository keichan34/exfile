defmodule Exfile.S.Image do
  use Ecto.Schema

  schema "images" do
    field(:image, Exfile.Ecto.File)
    field(:image_content_type, :string)
    field(:image_filename, :string)
    field(:image_custom_filename, :string)
  end
end
