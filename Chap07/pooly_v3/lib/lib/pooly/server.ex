defmodule Pooly.Server do
  use GenServer

  @type worker() :: pid()
  @type pool_sup() :: pid()
  @type pool_name() :: atom()
  @type pool_conf() :: [mfa: mfa(), name: binary(), size: pos_integer()]

  # APIs
  @spec start_link([pool_conf()]) :: {:ok, pid()}
  def start_link(pools_config) do
    GenServer.start_link(
      __MODULE__,
      pools_config,
      name: __MODULE__
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
  def init(pools_config) do
    pools_config
    |> Enum.each(
      fn pool_config -> send(self(), {:start_pool, pool_config})
    end)

    {:ok, pools_config}
  end

  @impl GenServer
  def handle_info({:start_pool, pool_config}, state) do
    child_spec = {Pooly.PoolSupervisor, pool_config}
    {:ok, _pool_sup} = DynamicSupervisor.start_child(Pooly.PoolsSupervisor, child_spec)

    {:noreply, state}
  end
end
