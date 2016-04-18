defmodule Exfile.Token do
  @moduledoc false

  @spec verify_token(Path.t, String.t) :: boolean
  def verify_token(path, token) do
    case Base.url_decode64(token) do
      {:ok, hmac} ->
        hmac == do_generate_token(path)
      :error ->
        false
    end
  end

  @spec build_path(Path.t) :: Path.t
  def build_path(path),
    do: Path.join(generate_token(path), path)

  @spec generate_token(Path.t) :: String.t
  def generate_token(path),
    do: do_generate_token(path) |> Base.url_encode64

  defp do_generate_token(path),
    do: :crypto.hmac(:sha256, Exfile.Config.secret, path)
end
