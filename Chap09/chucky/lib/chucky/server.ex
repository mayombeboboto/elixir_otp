defmodule Chucky.Server do
  use GenServer

  # API Functions
  @spec start_link(term()) :: {:ok, pid()}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], [name: {:global, __MODULE__}])
  end

  @spec fact() :: binary()
  def fact(), do: GenServer.call({:global, __MODULE__}, :fact)

  # Callback Functions
  @impl GenServer
  def init([]) do
    :rand.seed(:exsss, :os.timestamp)
    facts =
      "facts.txt"
      |> File.read!()
      |> String.split("\n")
    {:ok, facts}
  end

  @impl GenServer
  def handle_call(:fact, _from, facts) do
    random_fact =
      facts
      |> Enum.shuffle()
      |> List.first()
    {:reply, random_fact, facts}
  end
end
