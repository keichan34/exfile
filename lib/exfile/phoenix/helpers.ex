if Code.ensure_loaded?(Phoenix.HTML) do

defmodule Exfile.Phoenix.Helpers do
  @moduledoc """
  View helpers to use Exfile in your Phoenix app.

  To use these helpers, import it in the `view` section of your `web/web.ex`
  file.

      defmodule MyApp.Web do
        def view do
          quote do
            use Phoenix.View, root: "web/templates"
            ...
            import Exfile.Phoenix.Helpers
          end
        end
      end

  """

  alias Exfile.{Config, Token}

  @doc """
  Returns the absolute path of a file with the options passed.
  """
  @spec exfile_path(%Exfile.File{}) :: String.t
  @spec exfile_path(%Exfile.File{}, [{atom, any}, ...]) :: String.t
  def exfile_path(%Exfile.File{} = file, opts \\ []) do
    path = [file.backend.backend_name]

    path = case Keyword.fetch(opts, :processor) do
      {:ok, processor} ->
        path ++ [processor]
      :error -> path
    end

    path = case Keyword.fetch(opts, :processor_args) do
      {:ok, processor_args} ->
        path ++ processor_args
      :error -> path
    end

    format = Keyword.get(opts, :format)
    format_ext = if format, do: "." <> format
    path = path ++ [file.id, "file#{format_ext}"]

    "/attachments/" <> (Enum.join(path, "/") |> Token.build_path)
  end

  @doc """
  Returns the absolute URL of a file with the options passed.

  The first argument accepts any parameter that the Phoenix generated _url
  function takes. If `cdn_host` is configured for Exfile, this first argument
  is not necessary.
  """
  def exfile_url(base, file \\ [], opts \\ [])

  def exfile_url(%Exfile.File{} = file, opts, _),
    do: do_exfile_url(nil, file, opts)
  def exfile_url(map, file, opts) when is_map(map),
    do: do_exfile_url(map, file, opts)
  def exfile_url(endpoint, file, opts) when not is_nil(endpoint) and is_atom(endpoint),
    do: do_exfile_url(endpoint, file, opts)

  defp do_exfile_url(base, %Exfile.File{} = file, opts) do
    hostname_with_proto_for_url(base) <> exfile_path(file, opts)
  end

  defp hostname_with_proto_for_url(base) do
    Config.cdn_host || Phoenix.Router.Helpers.url(nil, base)
  end
end

end
