defmodule Pooly.Server do
  use GenServer
  alias Pooly.WorkerSupervisor

  defmodule State do
    defstruct [
      sup: nil,
      size: nil,
      mfa: nil,
      workers: [],
      worker_sup: nil
    ]
  end

  # APIs
  @spec start_link(pid(), keyword()) :: {:ok, pid()}
  def start_link(sup, pool_config) do
    GenServer.start_link(
      __MODULE__,
      [sup, pool_config],
      name: __MODULE__)
  end

  # Callback Functions
  def init([sup, pool_config]) when is_pid(sup) do
    init(pool_config, %State{ sup: sup })
  end

  defp init([{:mfa, mfa}|rest], state) do
    init(rest, %{ state | mfa: mfa })
  end

  defp init([{:size, size}|rest], state) do
    init(rest, %{ state | size: size })
  end

  defp init([_config|rest], state) do
    init(rest, state)
  end

  defp init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_info(
    :start_worker_supervisor,
    state=%State{
      sup: main_sup,
      mfa: mfa,
      size: size }) do
    {:ok, worker_sup} =
      Supervisor.start_child(main_sup, {WorkerSupervisor, [size: size]})

    workers = prepopulate(worker_sup, mfa, size)
    state = %{ state | worker_sup: worker_sup, workers: workers }
    {:noreply, state}
  end

  # Private Functions
  defp prepopulate(worker_sup, mfa, size) do
    1..size
    |> Enum.map(fn _value -> WorkerSupervisor.start_child(worker_sup, mfa) end)
    |> Enum.map(fn {:ok, pid} -> pid end)
  end
end
