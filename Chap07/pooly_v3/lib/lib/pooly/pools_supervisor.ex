defmodule Pooly.PoolsSupervisor do
  use DynamicSupervisor

  # APIs
  @spec start_link(term()) :: {:ok, pid()}
  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callback Functions
  @impl DynamicSupervisor
  def init([]) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5
    )
  end
end
