defmodule Greeter do
  require IEx

  def ohai(who, adjective) do
    greeting = "ohai!, #{adjective} #{who}"
    IEx.pry()
  end
end
