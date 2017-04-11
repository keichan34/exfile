defmodule Exfile.Ecto.CastFilenameTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset, only: [cast: 3]
  import Exfile.Ecto.CastFilename

  test "assigns content type correctly" do
    changeset = cast(initial_changeset(), %{ image: image_file() }, [:image])
      |> cast_filename(:image)

    assert changeset.changes[:image_filename] == "sample.jpg"
  end

  test "doesn't assign anything if file is not present in changeset" do
    changeset = cast(initial_changeset(), %{ image: nil }, [:image])
      |> cast_filename(:image)

    assert changeset.changes[:image] == nil
    assert changeset.changes[:image_filename] == nil
  end

  test "ability to use custom field name" do
    changeset = cast(initial_changeset(), %{ image: image_file() }, [:image])
      |> cast_filename(:image, :image_custom_filename)

    assert changeset.changes[:image_custom_filename] == "sample.jpg"
  end

  defp initial_changeset() do
    %Exfile.S.Image{}
  end

  defp image_file() do
    %Plug.Upload{ path: "test/fixtures/sample.jpg", filename: "sample.jpg" }
  end
end
