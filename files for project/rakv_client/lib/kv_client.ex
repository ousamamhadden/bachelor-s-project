defmodule KvClient do
  @moduledoc """
  Documentation for `RakvClient`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RakvClient.hello()
      :world

  """
  @server_normal :"rakv@rakv-3.rakv-cluster.ngcp-dev.svc.cluster.local"
  def startt(args) do
    wait_for_ra_nodes(args)
    send_put(0)
  end

  def hello do
    :world
  end

  defp wait_for_ra_nodes(args) do
    if length(args) != length(Node.list()) do
      # make sure ra is not started until the nodes are connected
      wait_for_ra_nodes(args)
    end
  end

  defp send_put(a) do
    start = :os.system_time(:nanosecond)
    resp = :rpc.call(@server_normal, Normalkv, :put, [Normalkv, :c, a])
    finish = :os.system_time(:nanosecond)
    delta = finish - start

    :telemetry.execute(
      [:raftclient, :normalkv, :put],
      %{deltatime: delta}
    )

    :timer.sleep(1000)
    send_get(a)
  end

  defp send_get(a) do
    start = :os.system_time(:nanosecond)
    resp = :rpc.call(@server_normal, Normalkv, :get, [Normalkv, :c])
    finish = :os.system_time(:nanosecond)
    delta = finish - start

    :telemetry.execute(
      [:raftclient, :normalkv, :get],
      %{deltatime: delta}
    )

    :timer.sleep(1000)

    send_put(a + 1)
  end
end
