defmodule Exfile.EctoTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Exfile.Ecto

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Exfile.Repo)

    image_file = %Plug.Upload{ path: "test/fixtures/sample.jpg", filename: "sample.jpg" }
    changeset = cast(%Exfile.S.Image{}, %{image: image_file}, [:image])
    changeset_without_image = cast(%Exfile.S.Image{}, %{}, [])

    {:ok, %{ changeset: changeset, changeset_without_image: changeset_without_image }}
  end

  test "prepare_uploads/2 saves a file from the cache backend to the store backend", %{changeset: changeset} do

    assert get_field(changeset, :image).backend.backend_name == "cache"
    assert {:ok, data} = changeset
    |> prepare_uploads([:image])
    |> Exfile.Repo.insert

    assert data.image.backend.backend_name == "store"
  end

  test "prepare_uploads/2 ignores a file field with null value", %{changeset_without_image: changeset} do

    assert get_field(changeset, :image) == nil

    assert {:ok, data} = changeset
    |> prepare_uploads([:image])
    |> Exfile.Repo.insert

    assert data.image == nil
  end


  test "prepare_uploads/2 doesn't save the file to store if there are errors", %{changeset: changeset} do
    changeset = add_error(changeset, :image_content_type, "invalid")

    assert {:error, error_changeset} = changeset
    |> prepare_uploads([:image])
    |> Exfile.Repo.insert

    assert get_field(error_changeset, :image).id == get_field(changeset, :image).id
    assert get_field(error_changeset, :image).backend.backend_name == "cache"
  end

end
