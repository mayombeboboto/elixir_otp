defmodule Pooly.PoolServer do
  use GenServer

  defmodule State do
    defstruct sup: nil,
              mfa: nil,
              size: nil,
              workers: [],
              overflow: 0,
              waiting: nil,
              monitors: nil,
              worker_sup: nil,
              max_overflow: nil
  end

  @type block() :: boolean()

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

  @spec checkout(pool_name(), block(), timeout()) :: worker() | :noproc
  def checkout(pool_name, block, timeout) do
    GenServer.call(pool_name, {:checkout, block, self()}, timeout)
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
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting = :queue.new()

    state = %State{
      sup: sup,
      monitors: monitors,
      waiting: waiting
    }

    init(pool_config, state)
  end

  defp init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  defp init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  defp init([{:max_overflow, max_overflow} | rest], state) do
    init(rest, %{state | max_overflow: max_overflow})
  end

  defp init([_config | rest], state) do
    init(rest, state)
  end

  defp init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:checkout, block, from_pid}, from, state) do
    %State{
      mfa: mfa,
      waiting: waiting,
      monitors: monitors,
      overflow: overflow,
      worker_sup: worker_sup,
      max_overflow: max_overflow
    } = state

    case state.workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(state.monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] when max_overflow > 0 and overflow < max_overflow ->
        worker = new_worker(worker_sup, mfa)
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | overflow: overflow+1}}

      [] when block == true ->
        ref = Process.monitor(from_pid)
        waiting = :queue.in({from, ref}, waiting)
        {:noreply, %{ state | waiting: waiting }, :infinity}

      [] ->
        {:reply, :full, state}
    end
  end

  def handle_call(:status, _from, state) do
    reply = {state_name(state),
             length(state.workers),
             :ets.info(state.monitors, :size)}
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:checkin, worker}, state) do
    case :ets.lookup(state.monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, pid)
        {:noreply, handle_checkin(worker, state)}

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
    child_spec = {Pooly.WorkerSupervisor, []}
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

  def handle_info({:EXIT, worker, _reason}, state) do
    case :ets.lookup(state.monitors, worker) do
      [{worker, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, worker)
        {:noreply, handle_worker_exit(worker, state)}

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
    |> Enum.map(fn _ -> new_worker(worker_sup, mfa) end)
  end

  defp handle_checkin(worker, state) do
    %State{
      workers: workers,
      waiting: waiting,
      overflow: overflow,
      monitors: monitors,
      worker_sup: worker_sup
    } = state

      case :queue.out(waiting) do
        {{:value, {from, ref}}, left} ->
          true = :ets.insert(monitors, {worker, ref})
          GenServer.reply(from, worker)
          %{state | waiting: left}
        {:empty, empty} when overflow > 0 ->
          :ok = dismiss_worker(worker_sup, worker)
          %{state | waiting: empty, overflow: overflow-1}
        {:empty, empty} ->
          %{state | waiting: empty, workers: [worker|workers], overflow: 0}
      end
  end

  defp handle_worker_exit(_worker, state) do
    %State{
      mfa: mfa,
      workers: workers,
      worker_sup: worker_sup
    } = state
    if state.overflow > 0 do
      %{state | overflow: state.overflow-1}
    else
      %{state | workers: [new_worker(worker_sup, mfa)|workers]}
    end
  end

  defp dismiss_worker(worker_sup, worker) do
    true = Process.unlink(worker)
    Supervisor.terminate_child(worker_sup, worker)
  end

  defp new_worker(worker_sup, mfa) do
    {:ok, worker} = Pooly.WorkerSupervisor.start_child(worker_sup, mfa)
    worker
  end

  defp state_name(state) when state.overflow < 1 do
    case length(state.workers) == 0 do
      true ->
        if state.max_overflow < 1 do
          :full
        else
          :overflow
        end
      false ->
        :ready
    end
  end

  defp state_name(%State{overflow: value, max_overflow: value}) do
    :full
  end

  defp state_name(_state) do
    :overflow
  end
end
