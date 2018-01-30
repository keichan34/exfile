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

  alias Exfile.{Config, Token, File}

  @type exfile_path_opts ::
    [
      processor: String.t, processor_args: [String.t], format: String.t,
      filename: String.t
    ]

  @doc """
  Returns the absolute path of a file with the options passed.

  Valid options:

  * `processor`: Specify a processor to run before outputing the file (string).
  * `processor_args`: Specify a list of arguments to pass to the processor. Requires `processor` to be set.
  * `format`: Specify the format of the file
  * `filename`: Customize the filename (default is `file.[format]` or `file` if format is not specified). Note that this will override anything that is set in `format`.
  """
  @spec exfile_path(File.t) :: String.t
  @spec exfile_path(File.t, exfile_path_opts) :: String.t
  def exfile_path(%File{} = file, opts \\ []) do
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
    filename = Keyword.get(opts, :filename)
      |> case do
        nil -> "file#{format_ext}"
        filename -> filename
      end

    path = path ++ [file.id, filename]

    "/attachments/" <> (("/" <> Enum.join(path, "/")) |> Token.build_path)
  end

  @doc """
  Returns the absolute URL of a file with the options passed.

  See `exfile_path/2` for valid options.

  The first argument accepts any parameter that the Phoenix generated `_url`
  function takes. If `cdn_host` is configured for Exfile, this first argument
  is not necessary.
  """
  @spec exfile_url(File.t) :: String.t
  @spec exfile_url(File.t, exfile_path_opts) :: String.t
  @spec exfile_url(File.t, exfile_path_opts, []) :: String.t
  @spec exfile_url(Plug.Conn.t | Phoenix.Socket.t | URI.t, File.t, exfile_path_opts) :: String.t
  @spec exfile_url(atom, File.t, exfile_path_opts) :: String.t

  def exfile_url(base, file \\ [], opts \\ [])

  def exfile_url(%File{} = file, opts, _),
    do: do_exfile_url(nil, file, opts)
  def exfile_url(%{__struct__: mod} = other, file, opts) when mod in [Plug.Conn, Phoenix.Socket, URI],
    do: do_exfile_url(other, file, opts)
  def exfile_url(endpoint, file, opts) when not is_nil(endpoint) and is_atom(endpoint),
    do: do_exfile_url(endpoint, file, opts)

  defp do_exfile_url(base, %File{} = file, opts) do
    hostname_with_proto_for_url(base) <> exfile_path(file, opts)
  end

  defp hostname_with_proto_for_url(base) do
    Config.cdn_host || Phoenix.Router.Helpers.url(nil, base)
  end
end

end
