defmodule Pooly.PoolsSupervisor do
  use DynamicSupervisor

  # APIs
  @spec start_link() :: {:ok, pid()}
  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_child(pid(), mfa()) :: {:ok, pid()}
  def start_child(supervisor, {mod, _func, args}) do
    DynamicSupervisor.start_child(supervisor, {mod, args})
  end

  # Callback Functions
  @impl Supervisor
  def init([]) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end
