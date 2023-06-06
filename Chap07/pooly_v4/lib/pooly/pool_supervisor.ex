defmodule Pooly.PoolSupervisor do
  use Supervisor

  @type pool_conf() :: [mfa: mfa(), name: binary(), size: pos_integer()]

  # API
  @spec start_link(pool_conf()) :: {:ok, pid()}
  def start_link(pool_config) do
    Supervisor.start_link(
      __MODULE__,
      pool_config
    )
  end

  @impl Supervisor
  def init(pool_config) do
    children = [{Pooly.PoolServer, {self(), pool_config}}]
    Supervisor.init(children, strategy: :one_for_all)
  end
end
