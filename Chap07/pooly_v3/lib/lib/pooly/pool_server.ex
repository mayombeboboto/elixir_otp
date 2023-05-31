defmodule Pooly.PoolServer do
  use GenServer

  defmodule State do
    defstruct sup: nil,
              size: nil,
              mfa: nil,
              workers: [],
              monitors: nil,
              worker_sup: nil
  end

  @type worker() :: pid()
  @type pool_sup() :: pid()
  @type pool_name() :: atom()
  @type pool_conf() :: [mfa: mfa(), name: binary(), size: pos_integer()]
  # APIs
  @spec start_link({pool_sup(), pool_conf()}) :: {:ok, pid()}
  def start_link({sup, pool_config}) do
    GenServer.start_link(
      __MODULE__,
      {sup, pool_config},
      name: Keyword.get(pool_config, :name)
    )
  end

  @spec checkout(pool_name()) :: worker() | :noproc
  def checkout(pool_name) do
    GenServer.call(pool_name, {:checkout, self()})
  end

  @spec checkin(pool_name(), worker()) :: no_return()
  def checkin(pool_name, worker_pid) do
    GenServer.cast(pool_name, {:checkin, worker_pid})
  end

  @spec status(pool_name()) :: {integer(), term() | :undefined}
  def status(pool_name) do
    GenServer.call(pool_name, :status)
  end

  # Callback Functions
  @impl GenServer
  def init({sup, pool_config}) when is_pid(sup) do
    :erlang.process_flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
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
        true = :ets.insert(state.monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, state) do
    reply = {length(state.workers), :ets.info(state.monitors, :size)}
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:checkin, worker}, state) do
    case :ets.lookup(state.monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, pid)
        {:noreply, %{state | workers: [pid | state.workers]}}

      [] ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(
        :start_worker_supervisor,
        state = %State{
          sup: pool_sup,
          mfa: mfa,
          size: size
        }
      ) do
    child_spec = {Pooly.WorkerSupervisor, [size: size]}
    {:ok, worker_sup} = Supervisor.start_child(pool_sup, child_spec)

    workers = prepopulate(worker_sup, mfa, size)
    state = %{state | worker_sup: worker_sup, workers: workers}
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    case :ets.match(state.monitors, {:"$1", ref}) do
      [[^pid]] ->
        true = :ets.delete(state.monitors, pid)
        new_state = %{state | workers: [pid | state.workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, state = %State{mfa: mfa}) do
    case :ets.lookup(state.monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, pid)
        {:ok, worker} = Pooly.WorkerSupervisor.start_child(state.worker_sup, mfa)
        new_workers = [worker | state.workers]
        {:noreply, %{state| workers: new_workers}}

      [] ->
        {:noreply, state}
    end
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  # Private Functions
  defp prepopulate(worker_sup, mfa, size) do
    1..size
    |> Enum.map(fn _ -> (Pooly.WorkerSupervisor.start_child(worker_sup, mfa)) end)
    |> Enum.map(fn {:ok, pid} -> pid end)
  end
end
