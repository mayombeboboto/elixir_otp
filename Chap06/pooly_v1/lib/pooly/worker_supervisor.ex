defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  # APIs
  @spec start_link(term()) :: {:ok, pid()}
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg)
  end

  @spec start_child(pid(), atom(), term()) :: {:ok, pid()}
  def start_child(supervisor, mod, args) do
    DynamicSupervisor.start_child(supervisor, {mod, args})
  end

  # Callback Functions
  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5
    )
  end
end