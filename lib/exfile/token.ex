defmodule Exfile.Token do
  @moduledoc false

  @spec verify_token(Path.t, String.t) :: boolean
  def verify_token(path, token) do
    case Base.decode16(token, case: :lower) do
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
    do: do_generate_token(path) |> Base.encode16(case: :lower)

  defp do_generate_token(path),
    do: :crypto.hmac(:sha, Exfile.Config.secret, path)
end
