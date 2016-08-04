defmodule Exfile.ProcessorChain do
  @moduledoc """
  A module to run a chain of processors on a file.
  """

  alias Exfile.{LocalFile, ProcessorRegistry}

  @type uploadable :: %Exfile.File{} | %Exfile.LocalFile{}

  @type name :: String.t
  @type args :: [String.t, ...]
  @type opts :: [key: any]
  @type definition :: name | {name, args} | {name, args, opts}

  @doc """
  Apply a chain of processors to an uploadable.

  If the list of processor definitions is empty, it will pass-through the
  uploadable argument untouched. If the list of processor definitions is not
  empty, it will coerce the uploadable argument in to a LocalFile, downloading
  it from the backend if necessary.

  The definition list accepts three different terms:

  * A string, representing the processor name to apply
  * A 2-element tuple: `{string, list of processor arguments}`
  * A 3-element tuple: `{string, list of processor arguments, list of processor options}`

  If a processor encounters an error, the chain is halted and the error is
  returned immediately in the format `{:error, reason}`.
  """
  @spec apply_processors([], uploadable) :: {:ok, uploadable}
  def apply_processors([], uploadable) do
    # Pass-through
    {:ok, uploadable}
  end

  @spec apply_processors([definition, ...], uploadable) :: {:ok, LocalFile.t} | {:error, atom}
  def apply_processors(processors, uploadable) do
    local_file = coerce_to_local_file(uploadable)
    do_process(processors, {:ok, local_file})
  end

  def coerce_to_local_file(%LocalFile{} = local_file),
    do: local_file
  def coerce_to_local_file(%Exfile.File{} = file) do
    case Exfile.File.open(file) do
      { :ok, local_file } -> local_file
      { :error, _ }       -> %LocalFile{}
    end
  end

  defp do_process(_, {:error, _} = error_term),
    do: error_term

  defp do_process([{name, args} | other], file),
    do: do_process([{name, args, []} | other], file)

  defp do_process([name | other], file) when is_binary(name),
    do: do_process([{name, [], []} | other], file)

  defp do_process([{name, args, opts} | other], {:ok, file}) do
    process_result = ProcessorRegistry.process(name, file, args, opts)
    do_process(other, process_result)
  end

  defp do_process([], file),
    do: file
end
