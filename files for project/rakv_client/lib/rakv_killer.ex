defmodule RakvKiller do
  @moduledoc """
  Documentation for `RakvClient`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RakvClient.hello()
      :world

  """

  def startt(_args) do
    IO.puts("Start killing")
    maxkills = String.to_integer(System.get_env("MAX_KILLS"))
    timebetweenkills = String.to_integer(System.get_env("TIME_BETWEEN_KILLS"))
    IO.puts(maxkills)
    IO.puts(timebetweenkills)
    :timer.sleep(60_000)
    IO.puts("Start killing 2")

    # leting things settle for a bit
    kill(maxkills, timebetweenkills)
  end

  defp kill(0, _sleep), do: IO.puts("FINISHED!!")

  defp kill(kills, sleep) do
    Enum.map(Node.list(), fn node -> IO.puts(node) end)

    case rem(kills, 3) do
      0 -> :rpc.call(:"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local", :init, :stop, [])
      1 -> :rpc.call(:"rakv@rakv-1.rakv-cluster.ngcp-dev.svc.cluster.local", :init, :stop, [])
      2 -> :rpc.call(:"rakv@rakv-2.rakv-cluster.ngcp-dev.svc.cluster.local", :init, :stop, [])
    end

    :timer.sleep(sleep)
    kill(kills - 1, sleep)
  end
end
