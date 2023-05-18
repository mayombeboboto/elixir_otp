defmodule Ring do
  @moduledoc """
  Documentation for `Ring`.
  """

  def link_processes(procs) do
    link_processes(procs, [])
  end

  def link_processes([proc_1, proc_2|rest], acc) do
    send(proc_1, {:link, proc_2})
    link_processes([proc_2|rest], [proc_1|acc])
  end
  def link_processes([proc|[]], acc) do
    first_process = List.last(acc)
    send(proc, {:link, first_process})
    :ok
  end

  def create_processes(number) do
    1..number |> Enum.map(fn _value -> spawn(fn -> loop() end) end)
  end

  def loop() do
    receive do
      {:link, link_to} when is_pid(link_to) ->
        Process.link(link_to)
        loop()
      :trap_exit ->
        Process.flag(:trap_exit, true)
        loop()
      :crash ->
        1/0
      {:EXIT, pid, reason} ->
        IO.puts("#{inspect(self())} received: {:EXIT, #{inspect(pid)}, #{reason}}")
        loop()
    end

  end
end
