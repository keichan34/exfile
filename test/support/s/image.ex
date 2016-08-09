defmodule Exfile.S.Image do
  use Ecto.Schema

  schema "images" do
    field :image, Exfile.Ecto.File
    field :image_content_type, :string
  end
end
