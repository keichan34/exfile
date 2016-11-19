defmodule Exfile.Ecto.ValidateFileSizeTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset, only: [cast: 3]
  import Exfile.Ecto.ValidateFileSize

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Exfile.Repo)

    :ok
  end

  test "passes with big file size limit" do
    changeset = cast(initial_changeset, %{ image: image_file }, [:image])
      |> validate_file_size(:image, 631)

    assert changeset.valid? == true

    assert {:ok, _image} = Exfile.Repo.insert(changeset)
  end

  test "invalid with small file limit" do
    changeset = cast(initial_changeset, %{ image: image_file }, [:image])
      |> validate_file_size(:image, 630)

    assert changeset.valid? == false
    assert changeset.errors == [image: {"file size is too big", []}]
  end

  test "passes with no file" do
    changeset = cast(initial_changeset, %{}, [:image])
      |> validate_file_size(:image, 631)

    assert changeset.valid? == true
  end

  defp initial_changeset do
    %Exfile.S.Image{}
  end

  defp image_file do
    %Plug.Upload{ path: "test/fixtures/sample.jpg", filename: "sample.jpg" }
  end
end
