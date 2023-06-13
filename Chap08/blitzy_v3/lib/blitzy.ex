defmodule Blitzy do
  @moduledoc """
  Documentation for `Blitzy`.
  """

  def run(number_of_workers, url) when number_of_workers > 0 do
    worker_fun = fn -> Blitzy.Worker.start(url) end

    1..number_of_workers
    |> Enum.map(fn _value -> Task.async(worker_fun) end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results()
  end

  defp parse_results(results) do
    {successes, _failures} = split_results(results)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    data = successes |> Enum.map(fn {:ok, time} -> time end)
    average_time = average_time(data)
    longest_time = Enum.max(data)
    shortest_time = Enum.min(data)

    IO.puts"""
    Total workers:     #{total_workers}
    Successful reqs:   #{total_success}
    Failed res:        #{total_failure}
    Average  (msecs):  #{average_time}
    Longest  (msecs):  #{longest_time}
    Shortest (msecs):  #{shortest_time}
    """
  end

  defp split_results(results) do
    fun = fn {:ok, _result} -> true
             _other -> false end
    Enum.split_with(results, fun)
  end

  defp average_time(list) do
    sum = Enum.sum(list)
    if sum > 0, do: sum / Enum.count(list), else: 0
  end
end
