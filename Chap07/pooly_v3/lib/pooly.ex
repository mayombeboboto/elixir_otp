defmodule Pooly do
  @moduledoc """
  Documentation for `Pooly`.
  """
  use Application
  alias Pooly.Server
  alias Pooly.SampleWorker

  @spec start(:normal, term()) :: {:ok, pid()}
  def start(_type, _args) do
    pools_config = [
      [name: "Pool1", mfa: {SampleWorker, :start_link, [:nil]}, size: 2],
      [name: "Pool2", mfa: {SampleWorker, :start_link, [:nil]}, size: 3],
      [name: "Pool3", mfa: {SampleWorker, :start_link, [:nil]}, size: 4]
    ]
    start_pool(pools_config)
  end

  @spec start_pool(keyword()) :: {:ok, pid()}
  def start_pool(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  @spec checkout(binary()) :: pid()
  def checkout(pool_name) do
    Server.checkout(pool_name)
  end

  @spec checkin(binary(), pid()) :: no_return()
  def checkin(pool_name, worker_pid) do
    Server.checkin(pool_name, worker_pid)
  end

  @spec status(binary()) :: {integer(), term() | :undefined}
  def status(pool_name) do
    Server.status(pool_name)
  end
end
