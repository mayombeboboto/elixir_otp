defmodule Pooly.Supervisor do
  use Supervisor

  @type pool_conf() :: [mfa: mfa(), name: binary(), size: pos_integer()]

  @spec start_link([pool_conf()]) :: {:ok, pid()}
  def start_link(pools_config) do
    Supervisor.start_link(
      __MODULE__,
      pools_config,
      name: __MODULE__
    )
  end

  @impl Supervisor
  def init(pools_config) do
    children = [
      {Pooly.PoolsSupervisor, []},
      {Pooly.Server, pools_config}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
