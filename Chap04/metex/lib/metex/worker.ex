defmodule Metex.Worker do
  use GenServer

  @name MW
  alias Metex.Utils
  @type response() :: :error | binary()

  ## Client APIs
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts ++ [name: MW])
  end

  @spec stop() :: no_return()
  def stop() do
    GenServer.cast(@name, :stop)
  end

  @spec get_temperature(binary()) :: response()
  def get_temperature(location) do
    GenServer.call(@name, {:location, location})
  end

  @spec get_stats() :: %{}
  def get_stats() do
    GenServer.call(@name, :get_stats)
  end

  @spec reset_stats() :: no_return()
  def reset_stats() do
    GenServer.cast(@name, :reset_stats)
  end

  ## Server Callbacks
  @impl GenServer
  def init(nil), do: {:ok, %{}}

  @impl GenServer
  def handle_call({:location, location}, _from, stats) do
    case Utils.temperature_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{location}: #{temp}°C", new_stats}
      _other ->
        {:reply, :error, stats}
    end
  end
  def handle_call(:get_stats, _from, stats) do
    {:reply, stats, stats}
  end

  @impl GenServer
  def handle_cast(:reset_stats, _stats) do
    {:noreply, %{}}
  end
  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  @impl GenServer
  def terminate(reason, stats) do
    IO.puts("Server terminated because of #{inspect(reason)}")
    inspect(stats)
    :ok
  end

  ## Internal Functions
  defp update_stats(old_stats, location) do
    case Map.has_key?(old_stats, location) do
      true -> Map.update!(old_stats, location, &(&1 + 1))
      false -> Map.put_new(old_stats, location, 1)
    end
  end
end
