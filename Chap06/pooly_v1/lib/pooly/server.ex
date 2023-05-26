defmodule Pooly.Server do
  use GenServer
  alias :ets, as: ETS
  alias Pooly.WorkerSupervisor
  import :erlang, only: [process_flag: 2]

  defmodule State do
    defstruct sup: nil,
              size: nil,
              mfa: nil,
              workers: [],
              monitors: nil,
              worker_sup: nil
  end

  # APIs
  @spec start_link({pid(), keyword()}) :: {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec checkout() :: pid() | :noproc
  def checkout do
    GenServer.call(__MODULE__, {:checkout, self()})
  end

  @spec checkin(pid()) :: no_return()
  def checkin(worker_pid) do
    GenServer.cast(__MODULE__, {:checkin, worker_pid})
  end

  @spec status() :: {integer(), term() | :undefined}
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Callback Functions
  @impl GenServer
  def init({sup, pool_config}) when is_pid(sup) do
    process_flag(:trap_exit, true)
    monitors = ETS.new(:monitors, [:private])
    init(pool_config, %State{ sup: sup, monitors: monitors })
  end

  defp init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  defp init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  defp init([_config | rest], state) do
    init(rest, state)
  end

  defp init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:checkout, from_pid}, _from, state) do
    case state.workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = ETS.insert(state.monitors, {worker, ref})
        {:reply, worker, %{ state | workers: rest }}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, {length(state.workers), ETS.info(state.monitors, :size)}, state}
  end

  @impl GenServer
  def handle_cast({:checkin, worker}, state) do
    case ETS.lookup(state.monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = ETS.delete(state.monitors, pid)
        {:noreply, %{ state | workers: [pid | state.workers] }}

      [] ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(
        :start_worker_supervisor,
        state = %State{
          sup: main_sup,
          mfa: mfa,
          size: size
        }
      ) do
    {:ok, worker_sup} =
      Supervisor.start_child(main_sup, {WorkerSupervisor, [size: size]})

    workers = prepopulate(worker_sup, mfa, size)
    state = %{ state | worker_sup: worker_sup, workers: workers }
    {:noreply, state}
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  # Private Functions
  defp prepopulate(worker_sup, mfa, size) do
    1..size
    |> Enum.map(fn _value -> WorkerSupervisor.start_child(worker_sup, mfa) end)
    |> Enum.map(fn {:ok, pid} -> pid end)
  end
end
