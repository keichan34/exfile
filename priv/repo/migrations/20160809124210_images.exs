defmodule Exfile.Repo.Migrations.Images do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :image, :string
      add :image_content_type, :string
    end
  end
end
