defmodule RakvClient do
  @servers [
    :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local",
    :"rakv@rakv-1.rakv-cluster.ngcp-dev.svc.cluster.local",
    :"rakv@rakv-2.rakv-cluster.ngcp-dev.svc.cluster.local"
  ]
  @moduledoc """
  Documentation for `RakvClient`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RakvClient.hello()
      :world

  """

  def startt(args) do
    wait_for_ra_nodes(args)
    maxcommands = String.to_integer(System.get_env("MAX_COMMANDS"))
    timebetweencommands = String.to_integer(System.get_env("TIME_BETWEEN_COMMANDS"))
    IO.puts(maxcommands)
    IO.puts(timebetweencommands)

    one_run(maxcommands, timebetweencommands)
    # send_command(server, maxcommands)
  end

  def one_run(_, _, 0), do: IO.puts("finished")

  def one_run(maxcommands, timebetweencommands) do
    1..maxcommands
    |> Enum.map(fn id ->
      Task.async(fn ->
        RakvClientHelper.senario_quatre(@server, id)
        :ok
      end)
    end)
    |> Enum.map(&Task.await/1)

    one_run(maxcommands, timebetweencommands - 1)
  end

  @spec hello :: :world
  def hello do
    :world
  end

  defp wait_for_ra_nodes(args) do
    if length(args) != length(Node.list()) do
      # make sure ra is not started until the nodes are connected
      wait_for_ra_nodes(args)
    end
  end

  # defp send_command(server, 0), do: IO.puts("FINISHED!!")

  # defp send_command(server, maxcommands) do
  #   RakvClientHelper.perfect_senario(server, maxcommands)
  #   send_command(server, maxcommands - 1)
  # end

  # defp send_put(_server, 0, _sleep), do: IO.puts("FINISHED!!")

  # defp send_put(server, a, time) do
  #   start = :os.system_time(:nanosecond)

  #   case :rpc.call(server, RAKV, :put, [
  #          {:test1234, server},
  #          String.to_atom(Integer.to_string(a)),
  #          a
  #        ]) do
  #     {:ok, resp, {:test1234, server}} ->
  #       finish = :os.system_time(:nanosecond)
  #       delta = finish - start

  #       :telemetry.execute(
  #         [:raftclient, :rakv, :put],
  #         %{deltatime: delta}
  #       )

  #       # IO.puts("Putting in RA...")
  #       # IO.puts(resp)
  #       :timer.sleep(time)
  #       send_get(server, a, time)

  #     _ ->
  #       IO.puts("ERROR ERROR BIIP BIIP")
  #       new_server = Enum.random(Node.list())

  #       send_put(new_server, a, time)
  #   end
  # end

  # defp send_get(server, a, time) do
  #   start = :os.system_time(:nanosecond)

  #   case :rpc.call(server, RAKV, :get, [{:test1234, server}, String.to_atom(Integer.to_string(a))]) do
  #     {:ok, resp, {:test1234, leader}} ->
  #       finish = :os.system_time(:nanosecond)
  #       delta = finish - start

  #       :telemetry.execute(
  #         [:raftclient, :rakv, :get],
  #         %{deltatime: delta}
  #       )

  #       IO.puts("Getting from RA...")
  #       IO.puts(resp)
  #       :timer.sleep(time)
  #       send_put(leader, a - 1, time)

  #     _ ->
  #       IO.puts("ERROR ERROR BIIP BIIP")
  #       Enum.map(Node.list(), fn node -> IO.puts(node) end)
  #       new_server = Enum.random(Node.list())
  #       IO.puts("SELECTED NEW SERVER")
  #       IO.puts(new_server)
  #       send_get(new_server, a, time)
  #   end
  # end
end
