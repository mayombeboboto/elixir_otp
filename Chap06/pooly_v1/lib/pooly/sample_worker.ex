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

    # Callback Functions
    @impl GenServer
    def init(:ok) do
        {:ok, nil}
    end

    @impl GenServer
    def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state}
    end

    @impl GenServer
    def terminate(_reason, _state) do
        :ok
    end
end
