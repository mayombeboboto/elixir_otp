defmodule Blitzy.Supervisor do
  use Supervisor

  @spec start_link(any) :: {:ok, pid}
  def start_link(_args) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @impl Supervisor
  def init(:ok) do
    children = [{Task.Supervisor, [name: Blitzy.TasksSupervisor]}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
