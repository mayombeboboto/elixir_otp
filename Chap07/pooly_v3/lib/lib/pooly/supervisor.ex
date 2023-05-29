defmodule Pooly.Supervisor do
  use Supervisor

  alias Pooly.Server
  alias Pooly.PoolsSupervisor

  # API
  @spec start_link([keyword()]) :: {:ok, pid()}
  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config)
  end

  # Callback Function
  @impl Supervisor
  def init(pool_config) do
    children = [
      {PoolsSupervisor, []},
      {Server, {self(), pools_config}}
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end
end
