defmodule Exfile.BackendModTest do
  use ExUnit.Case, async: true

  @file_contents "hello there, how are you doing?"

  test "downloading an uploaded file results in the same file" do
    backend = Exfile.Config.get_backend("store")
    {:ok, file} = Exfile.BackendTest.upload_string(backend, @file_contents)
    {:ok, local_file} = Exfile.Backend.open(backend, file.id)
    {:ok, f} = Exfile.LocalFile.open(local_file)

    everything = IO.binread(f, :all) |> IO.chardata_to_string
    assert everything == @file_contents
  end

  test "downloading an file uploaded to a backend with a configured preprocessor results in the preprocessed file" do
    backend = Exfile.Config.get_backend("pre")
    {:ok, file} = Exfile.BackendTest.upload_string(backend, @file_contents)
    {:ok, local_file} = Exfile.Backend.open(backend, file.id)
    {:ok, f} = Exfile.LocalFile.open(local_file)

    everything = IO.binread(f, :all) |> IO.chardata_to_string
    assert everything == String.reverse(@file_contents)
  end

  test "downloading an file uploaded to a backend with a configured preprocessor and postprocessor results in the preprocessed file that has been postprocessed" do
    backend = Exfile.Config.get_backend("pre-post")
    {:ok, file} = Exfile.BackendTest.upload_string(backend, @file_contents)
    {:ok, local_file} = Exfile.Backend.open(backend, file.id)
    {:ok, f} = Exfile.LocalFile.open(local_file)

    everything = IO.binread(f, :all) |> IO.chardata_to_string
    {expected, _} = String.split_at(String.reverse(@file_contents), 5)
    assert everything == expected
  end
end
