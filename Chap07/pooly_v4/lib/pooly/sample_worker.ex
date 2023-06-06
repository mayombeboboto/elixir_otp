defmodule Pooly.SampleWorker do
  use GenServer

  # APIs
  @spec start_link(term()) :: {:ok, pid()}
  def start_link(_args) do
      GenServer.start_link(__MODULE__, :ok, [])
  end

  @spec stop(pid()) :: :ok
  def stop(server) do
      GenServer.call(server, :stop)
  end

  @spec work_for(pid(), pos_integer()) :: no_return()
  def work_for(server, duration) do
    GenServer.cast(server, {:work_for, duration})
  end

  # Callback Functions
  @impl GenServer
  def init(:ok) do
      Process.flag(:trap_exit, true)
      {:ok, nil}
  end

  @impl GenServer
  def handle_call(:stop, _from, state) do
      {:stop, :normal, :ok, state}
  end

  @impl GenServer
  def handle_cast({:work_for, duration}, state) do
    :timer.sleep(duration)
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(_info, state) do
      {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, _state) do
      :ok
  end
end
