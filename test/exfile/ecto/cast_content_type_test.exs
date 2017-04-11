defmodule Exfile.Ecto.CastContentTypeTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset, only: [cast: 3]
  import Exfile.Ecto.CastContentType

  test "assigns content type correctly" do
    changeset = cast(initial_changeset(), %{ image: image_file() }, [:image])
      |> cast_content_type(:image)

    assert changeset.changes[:image_content_type] == "image/jpeg"
  end

  test "doesn't assign anything if file is not present in changeset" do
    changeset = cast(initial_changeset(), %{ image: nil }, [:image])
      |> cast_content_type(:image)

    assert changeset.changes[:image_content_type] == nil
  end

  test "ability to use custom field name" do
    changeset = cast(initial_changeset(), %{ image: image_file() }, [:image])
      |> cast_content_type(:image, :image_custom_type)

    assert changeset.changes[:image_custom_type] == "image/jpeg"
  end

  defp initial_changeset() do
    data  = %{
      image: nil,
      image_content_type: nil,
      image_custom_type: nil
    }

    types = %{
      image: Exfile.Ecto.File,
      image_content_type: :string,
      image_custom_type: :string
    }

    { data, types }
  end

  defp image_file() do
    %Plug.Upload{ path: "test/fixtures/sample.jpg", filename: "sample.jpg" }
  end
end
