defmodule Pooly.Supervisor do
  use Supervisor

  alias Pooly.Server

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config)
  end

  @impl Supervisor
  def init(pool_config) do
    children = [{Server, {self(), pool_config}}]
    Supervisor.init(children, strategy: :one_for_all)
  end
end
