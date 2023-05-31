defmodule Pooly do
  @moduledoc """
  Documentation for `Pooly`.
  """
  use Application

  @type pool_name() :: atom()
  @type pool_conf() :: [mfa: mfa(), name: binary(), size: pos_integer()]

  @spec start(:normal, term()) :: {:ok, pid()}
  def start(_type, _args) do
    pools_config = [
      [name: :pool1, mfa: {Pooly.SampleWorker, :start_link, [:nil]}, size: 2],
      [name: :pool2, mfa: {Pooly.SampleWorker, :start_link, [:nil]}, size: 3],
      [name: :pool3, mfa: {Pooly.SampleWorker, :start_link, [:nil]}, size: 4]
    ]
    start_pools(pools_config)
  end

  @spec start_pools([pool_conf()]) :: {:ok, pid()}
  def start_pools(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  @spec checkout(pool_name()) :: pid()
  def checkout(pool_name) do
    Pooly.Server.checkout(pool_name)
  end

  @spec checkin(pool_name(), pid()) :: no_return()
  def checkin(pool_name, worker_pid) do
    Pooly.Server.checkin(pool_name, worker_pid)
  end

  @spec status(pool_name()) :: {integer(), term() | :undefined}
  def status(pool_name) do
    Pooly.Server.status(pool_name)
  end
end
