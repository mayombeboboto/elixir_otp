defmodule Blitzy.Worker do
  use Timex
  require Logger

  def start(url) do
    {timestamp, response} = Duration.measure(fn -> HTTPoison.get(url) end)
    handle_response({Duration.to_milliseconds(timestamp), response})
  end

  defp handle_response({msecs, {:ok, %HTTPoison.Response{status_code: code}}})
       when code >= 200 and code <= 304 do
    message = "worker [#{node()}-#{inspect(self())}] completed in #{msecs} msecs"
    Logger.info(message)
    {:ok, msecs}
  end

  defp handle_response({_msecs, {:error, reason}}) do
    message = "worker [#{node()}-#{inspect(self())}] error due to #{inspect(reason)}"
    Logger.info(message)
    {:error, reason}
  end

  defp handle_response({_msecs, _response}) do
    message = "worker [#{node()}-#{inspect(self())}] errored out"
    Logger.info(message)
    {:error, :unknown}
  end
end
