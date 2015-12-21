defmodule Exfile.Token do
  def verify_token(path, token) do
    case Base.url_decode64(token) do
      {:ok, hmac} ->
        hmac == do_generate_token(path)
      :error ->
        false
    end
  end

  def generate_token(path),
    do: do_generate_token(path) |> Base.url_encode64

  defp do_generate_token(path),
    do: :crypto.hmac(:sha256, Exfile.Config.secret, path)
end
