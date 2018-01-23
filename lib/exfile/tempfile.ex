# This module is a derivative of Plug.Upload under the Apache 2.0 license.
# The current form was adapted from https://raw.githubusercontent.com/elixir-lang/plug/57e9a1df01f4ef57a01d58b6eb2247df7f910286/lib/plug/upload.ex

defmodule Exfile.Tempfile do
  @moduledoc """
  A server (a `GenServer` specifically) that manages temporary files.

  Temporary files are stored in a temporary directory
  and removed from that directory after the process that
  requested the file dies.
  """

  @doc """
  Requests a random file to be created in the temporary directory
  with the given prefix.
  """
  @spec random_file(binary) ::
        {:ok, binary} |
        {:too_many_attempts, binary, pos_integer} |
        {:no_tmp, [binary]}
  def random_file(prefix) do
    GenServer.call(tempfile_server(), {:random, prefix})
  end

  @doc """
  Requests a random file to be created in the temporary directory
  with the given prefix. Raises on failure.
  """
  @spec random_file!(binary) :: binary | no_return
  def random_file!(prefix) do
    case random_file(prefix) do
      {:ok, path} ->
        path
      {:too_many_attempts, tmp, attempts} ->
        raise "tried #{attempts} times to create an uploaded file at #{tmp} but failed. What gives?"
      {:no_tmp, _tmps} ->
        raise "could not create a tmp directory to store uploads. Set PLUG_TMPDIR to a directory with write permission"
    end
  end

  @doc """
  """
  @spec register_file(binary) :: :ok
  def register_file(path) do
    GenServer.call(tempfile_server(), {:register_file, path})
  end

  defp tempfile_server() do
    Process.whereis(__MODULE__) ||
      raise "could not find process Exfile.Tempfile. Have you started the :exfile application?"
  end

  use GenServer

  @doc """
  Starts the temporary file handling server.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  ## Callbacks

  @max_attempts 10

  @doc false
  def init(:ok) do
    tmp = System.tmp_dir
    cwd = Path.join(File.cwd!, "tmp")
    ets = :ets.new(:exfile_tempfile, [:private])
    {:ok, {[tmp, cwd], ets}}
  end

  @doc false
  def handle_call({:random, prefix}, {pid, _ref}, {tmps, ets} = state) do
    case find_tmp_dir(pid, tmps, ets) do
      {:ok, tmp, paths} ->
        {:reply, open_random_file(prefix, tmp, 0, pid, ets, paths), state}
      {:no_tmp, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:register_file, path}, {pid, _ref}, {tmps, ets} = state) do
    case find_tmp_dir(pid, tmps, ets) do
      {:ok, _tmp, paths} ->
        :ets.update_element(ets, pid, {3, [path|paths]})
        {:reply, :ok, state}
      {:no_tmp, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(msg, from, state) do
    super(msg, from, state)
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, pid, _reason}, {_, ets} = state) do
    case :ets.lookup(ets, pid) do
      [{pid, _tmp, paths}] ->
        :ets.delete(ets, pid)
        Enum.each paths, &:file.delete/1
      [] ->
        :ok
    end
    {:noreply, state}
  end

  def handle_info(msg, state) do
    super(msg, state)
  end

  ## Helpers

  defp find_tmp_dir(pid, tmps, ets) do
    case :ets.lookup(ets, pid) do
      [{^pid, tmp, paths}] ->
        {:ok, tmp, paths}
      [] ->
        if tmp = ensure_tmp_dir(tmps) do
          :erlang.monitor(:process, pid)
          :ets.insert(ets, {pid, tmp, []})
          {:ok, tmp, []}
        else
          {:no_tmp, tmps}
        end
    end
  end

  defp ensure_tmp_dir(tmps) do
    {mega, _, _} = :os.timestamp
    subdir = "/exfile-" <> i(mega)
    Enum.find_value(tmps, &write_tmp_dir(&1 <> subdir))
  end

  defp write_tmp_dir(path) do
    case File.mkdir_p(path) do
      :ok -> path
      {:error, _} -> nil
    end
  end

  defp open_random_file(prefix, tmp, attempts, pid, ets, paths) when attempts < @max_attempts do
    path = path(prefix, tmp)

    case :file.write_file(path, "", [:write, :raw, :exclusive, :binary]) do
      :ok ->
        :ets.update_element(ets, pid, {3, [path|paths]})
        {:ok, path}
      {:error, reason} when reason in [:eexist, :eacces] ->
        open_random_file(prefix, tmp, attempts + 1, pid, ets, paths)
    end
  end

  defp open_random_file(_prefix, tmp, attempts, _pid, _ets, _paths) do
    {:too_many_attempts, tmp, attempts}
  end

  @compile {:inline, i: 1}

  defp i(integer), do: Integer.to_string(integer)

  defp path(prefix, tmp) do
    {_mega, sec, micro} = :os.timestamp
    scheduler_id = :erlang.system_info(:scheduler_id)
    tmp <> "/" <> prefix <> "-" <> i(sec) <> "-" <> i(micro) <> "-" <> i(scheduler_id)
  end
end
