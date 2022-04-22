defmodule RakvClientHelper do
  @server :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"
  #   ,
  #   :"rakv@rakv-1.rakv-cluster.ngcp-dev.svc.cluster.local",
  #   :"rakv@rakv-2.rakv-cluster.ngcp-dev.svc.cluster.local"
  # ]
  import Opencensus.Trace

  def group_call_request(server, id) do
    spanCtx = :oc_trace.start_span("client-call-raft", :ocp.current_span_ctx())

    resp =
      :rpc.call(server, RAMiniGroupCall, :group_call_request, [
        {:mini_group_call, server},
        id,
        spanCtx
      ])

    :oc_trace.finish_span(spanCtx)
    resp
  end

  def resource_update_response(server, id) do
    :rpc.call(server, RAMiniGroupCall, :resource_update_response, [
      {:mini_group_call, server},
      id
    ])
  end

  def transmission_started_indication(server, id) do
    :rpc.call(server, RAMiniGroupCall, :transmission_started_indication, [
      {:mini_group_call, server},
      id
    ])
  end

  def transmission_ceased_indication(server, id) do
    :rpc.call(server, RAMiniGroupCall, :transmission_ceased_indication, [
      {:mini_group_call, server},
      id
    ])
  end

  def group_call_termination_at_endpoint(server, id) do
    :rpc.call(server, RAMiniGroupCall, :group_call_termination_at_endpoint, [
      {:mini_group_call, server},
      id
    ])
  end

  def group_call_termination_prolong(server, id) do
    :rpc.call(server, RAMiniGroupCall, :group_call_termination_prolong, [
      {:mini_group_call, server},
      id
    ])
  end

  def perfect_senario(server, id) do
    id = String.to_atom(Integer.to_string(id))
    start = :os.system_time(:nanosecond)

    server = repeat_til_success(&group_call_request/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :group_call_request],
      %{deltatime: delta}
    )

    start = :os.system_time(:nanosecond)
    server = repeat_til_success(&resource_update_response/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :resource_update_response],
      %{deltatime: delta}
    )

    # for _ <- 1..10, do: transmission_started_indication(server, id, make_ref())
    server = repeat_til_success(&transmission_ceased_indication/2, server, id)

    start = :os.system_time(:nanosecond)

    _server = repeat_til_success(&group_call_termination_at_endpoint/2, server, id)

    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :group_call_termination_at_endpoint],
      %{deltatime: delta}
    )
  end

  # the client does not send any requests when the call_state is terminating and waits for a timer in ra server to timeout
  def senario_dos(server, id) do
    id = String.to_atom(Integer.to_string(id))
    start = :os.system_time(:nanosecond)

    server = repeat_til_success(&group_call_request/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :group_call_request],
      %{deltatime: delta}
    )

    server = repeat_til_success(&resource_update_response/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :resource_update_response],
      %{deltatime: delta}
    )

    # for _ <- 1..10, do: transmission_started_indication(server, id, make_ref())
    server = repeat_til_success(&transmission_ceased_indication/2, server, id)

    # start = :os.system_time(:nanosecond)

    # waiting for termination timer to timeout
    Process.sleep(2500)

    resp = group_call_termination_at_endpoint(server, id)
    IO.puts("#{inspect(resp)}")
    # finish = :os.system_time(:nanosecond)
    # delta = -start + finish

    # :telemetry.execute(
    #   [:raftclient, :ra_mini_group_call, :group_call_termination_at_endpoint],
    #   %{deltatime: delta}
    # )
  end

  def senario_three(server, id) do
    id = String.to_atom(Integer.to_string(id))
    start = :os.system_time(:nanosecond)

    server = repeat_til_success(&group_call_request/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :group_call_request],
      %{deltatime: delta}
    )

    server = repeat_til_success(&resource_update_response/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :resource_update_response],
      %{deltatime: delta}
    )

    repeat_til_success(&transmission_started_indication/2, server, id)
    Process.sleep(500)

    # waiting for call_duration timer to timeout
    Process.sleep(2500)

    server = repeat_til_success(&transmission_ceased_indication/2, server, id)

    start = :os.system_time(:nanosecond)

    _resp = repeat_til_success(&group_call_termination_at_endpoint/2, server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :group_call_termination_at_endpoint],
      %{deltatime: delta}
    )
  end

  def senario_quatre(server, id) do
    id = String.to_atom(Integer.to_string(id))
    start = :os.system_time(:nanosecond)

    group_call_request(server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :group_call_request],
      %{deltatime: delta}
    )

    start = :os.system_time(:nanosecond)

    resource_update_response(server, id)
    finish = :os.system_time(:nanosecond)
    delta = -start + finish

    :telemetry.execute(
      [:raftclient, :ra_mini_group_call, :resource_update_response],
      %{deltatime: delta}
    )

    # waiting for both timers to timeout
    Process.sleep(2500)

    group_call_termination_prolong(server, id)
    # IO.puts("#{inspect(resp)}")
  end

  def repeat_til_success(function, server, id) do
    case function.(server, id) do
      {:ok, resp, {:mini_group_call, leader}} ->
        leader

      resp ->
        IO.puts("#{inspect(resp)}")
        IO.puts("#{inspect(Node.list())}")

        new_server =
          Enum.filter(@servers -- [server], fn a -> a in Node.list() end)
          |> Enum.random()

        :timer.sleep(100)
        repeat_til_success(function, new_server, id)
    end
  end
end
