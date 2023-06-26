defmodule Blitzy do
  @moduledoc """
  Documentation for `Blitzy`.
  """
  use Application

  @type type() :: atom()
  @type args() :: list()

  @spec start(type(), args()) :: {:ok, pid()}
  def start(_type, _args) do
    Blitzy.Supervisor.start_link(:ok)
  end
end
