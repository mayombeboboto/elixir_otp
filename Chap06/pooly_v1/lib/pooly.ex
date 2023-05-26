defmodule Pooly do
  @moduledoc """
  Documentation for `Pooly`.
  """
  use Application
  alias Pooly.Server
  alias Pooly.SampleWorker

  @spec start(:normal, term()) :: {:ok, pid()}
  def start(_type, _args) do
    pool_config = [mfa: {SampleWorker, :start_link, [:nil]}, size: 5]
    start_pool(pool_config)
  end

  @spec start_pool(keyword()) :: {:ok, pid()}
  def start_pool(pool_config) do
    Pooly.Supervisor.start_link(pool_config)
  end

  @spec checkout() :: pid()
  def checkout do
    Server.checkout()
  end

  @spec checkin(pid()) :: no_return()
  def checkin(worker_pid) do
    Server.checkin(worker_pid)
  end

  @spec status() :: {integer(), term() | :undefined}
  def status do
    Server.status()
  end
end
