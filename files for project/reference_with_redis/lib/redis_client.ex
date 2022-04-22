defmodule MiniGroupCall.RedisClient do
  def start do
    concurrent_requests = String.to_integer(System.get_env("CONCURRENT_REQUESTS"))
    iterations = String.to_integer(System.get_env("ITERATIONS"))
    IO.puts(concurrent_requests)
    IO.puts(iterations)
    # try_pinging_redis("refredis")
    Process.sleep(10000)
    script = resource_update_script()
    hash = MiniGroupCall.Redix.command(["SCRIPT", "LOAD", script])
    Application.put_env(:redis_ref, :resource_update_script, hash)
    # wait for redis
    IO.puts("got here 0")
    one_run(concurrent_requests, iterations)
  end

  def one_run(_, 0), do: IO.puts("finished")

  def one_run(maxcommands, timebetweencommands) do
    1..maxcommands
    |> Enum.map(fn id ->
      Task.async(fn ->
        senario_one(id)
        :ok
      end)
    end)
    |> Enum.map(&Task.await/1)

    one_run(maxcommands, timebetweencommands - 1)
  end

  def senario_one(id) do
    # id =
    start = :os.system_time(:nanosecond)
    MiniGroupCall.group_call_request(id)
    finish = :os.system_time(:nanosecond)
    delta = finish - start

    :telemetry.execute(
      [:referenceclient, :redis, :group_call_request],
      %{deltatime: delta}
    )

    IO.puts("#{inspect(delta)}")
    start = :os.system_time(:nanosecond)

    MiniGroupCall.resource_update_response(id)

    finish = :os.system_time(:nanosecond)
    delta = finish - start

    :telemetry.execute(
      [:referenceclient, :redis, :resource_update],
      %{deltatime: delta}
    )

    # IO.puts("#{inspect(resp)}")

    # IO.puts("#{inspect(resp)}")

    _resp = MiniGroupCall.transmission_ceased_indication(id)
    # IO.puts("#{inspect(resp)}")

    _resp = MiniGroupCall.group_call_termination_at_endpoint(id)
    # IO.puts("#{inspect(resp)}")
  end

  # def repeat_til_success(function, server, id) do
  #   case function.(server, id) do
  #     {:ok, resp, {:mini_group_call, leader}} ->
  #       IO.puts("#{inspect(resp)}")
  #       leader

  #     resp ->
  #       IO.puts("#{inspect(resp)}")
  #       new_server = Enum.random(Node.list())
  #       :timer.sleep(1000)
  #       repeat_til_success(function, new_server, id)
  #   end
  # end

  def try_pinging_redis(host) do
    try do
      resp = Redix.start_link(host: host, password: "mypassword")
      IO.puts("#{inspect(resp)}")

      case resp do
        {:ok, conn} ->
          resp = Redix.command(conn, ["PING"])
          IO.puts("#{inspect(resp)}")

          MiniGroupCall.Redix.command(["PING"])

        _ ->
          IO.puts("host name " <> host <> " failed")
      end
    rescue
      _ -> IO.puts("host name " <> host <> " failed")
    end
  end

  defp resource_update_script do
    """
    if redis.call('EXISTS', ARGV[1]) == 1 then
      redis.call("HMSET", ARGV[1], "call_state", "transmitting")
      return 'OK'
    else
      return 'ERROR'
    end
    """
  end
end
