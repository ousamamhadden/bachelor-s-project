defmodule RAMiniGroupCall do
  @moduledoc """
  Documentation for `RAKV`.
  """

  import Opencensus.Trace

  @ra_cluster_name :mini_group_call
  @raft_starter :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"

  def start_system(_nodes) do
    # cluster starter needs to wait a bit for all node to start ra
    IO.puts("I got here 111")

    if File.exists?('rakvdata/' ++ Atom.to_charlist(Node.self())) do
      # :ra.start(data_dir: '/app/rakvdata', wal_data_dir: '/app')
      :ra.start(data_dir: '/app/rakvdata')
      :ra.restart_server({@ra_cluster_name, Node.self()})
      IO.puts("Volume is persistant!!!")
    else
      # :ra.start(data_dir: '/app/rakvdata', wal_data_dir: '/app')
      :ra.start(data_dir: '/app/rakvdata')

      if Node.self() == @raft_starter do
        start_cluster()
        IO.puts("I got here 222")
      else
        {:ok, _, _} =
          :ra.add_member(
            {@ra_cluster_name, @raft_starter},
            {@ra_cluster_name, Node.self()}
          )

        :ok = start_server()
      end
    end
  end

  @behaviour :ra_machine

  def hello do
    :world
  end

  @impl true
  def init(_config) do
    %{}
  end

  @impl true
  def apply(_metadata, {:group_call_request, id, ctx}, state) do
    spanCtx = :oc_trace.start_span("raft-apply", ctx)
    resp = MiniGroupCall.group_call_request(state, id, spanCtx)
    :oc_trace.finish_span(spanCtx)
    resp
  end

  def apply(_metadata, {:resource_update_response, id}, state) do
    MiniGroupCall.resource_update_response(state, id)
  end

  def apply(_metadata, {:transmission_started_indication, id}, state) do
    MiniGroupCall.transmission_started_indication(state, id)
  end

  def apply(_metadata, {:transmission_ceased_indication, id}, state) do
    MiniGroupCall.transmission_ceased_indication(state, id)
  end

  def apply(_metadata, {:group_call_termination_at_endpoint, id}, state) do
    MiniGroupCall.group_call_termination_at_endpoint(state, id)
  end

  def apply(_metadata, {:group_call_termination_prolong, id}, state) do
    MiniGroupCall.group_call_termination_prolong(state, id)
  end

  def apply(_metadata, {:timeout, {id, :termination_timer}}, state) do
    IO.puts("#{inspect({id, :termination_timer})}")
    MiniGroupCall.group_call_termination_at_endpoint(state, id)
  end

  def apply(_metadata, {:timeout, {id, :call_duration_timer}}, state) do
    IO.puts("#{inspect({id, :call_duration_timer})}")
    MiniGroupCall.transmission_ceased_indication(state, id)
  end

  ## Client API
  def group_call_request(serverId, id, ctx) do
    spanCtx = :oc_trace.start_span("command-to-raft", ctx)
    res = :ra.process_command(serverId, {:group_call_request, id, spanCtx})
    :oc_trace.finish_span(spanCtx)
    res
  end

  def resource_update_response(serverId, id) do
    :ra.process_command(serverId, {:resource_update_response, id})
  end

  def transmission_started_indication(serverId, id) do
    :ra.process_command(
      serverId,
      {:transmission_started_indication, id}
    )
  end

  def transmission_ceased_indication(serverId, id) do
    :ra.process_command(serverId, {:transmission_ceased_indication, id})
  end

  def call_duration_timer_expires(serverId, id) do
    :ra.process_command(
      serverId,
      {:call_duration_timer_expires, id}
    )
  end

  def group_call_termination_at_endpoint(serverId, id) do
    :ra.process_command(serverId, {:group_call_termination_at_endpoint, id})
  end

  def group_call_termination_prolong(serverId, id) do
    :ra.process_command(
      serverId,
      {:group_call_termination_prolong, id}
    )
  end

  def termination_timer_expires(serverId, id) do
    :ra.process_command(serverId, {:termination_timer_expires, id})
  end

  @spec start_cluster() ::
          {:error, :cluster_not_formed} | {:ok, [{atom, atom}, ...], keyword(atom)}
  def start_cluster() do
    serverIds = [{@ra_cluster_name, Node.self()}]
    machineConf = {:module, __MODULE__, %{}}
    :ra.start_cluster(:default, @ra_cluster_name, machineConf, serverIds)
  end

  @spec start_server :: :ok | {:error, any}
  def start_server() do
    my_id = {@ra_cluster_name, Node.self()}
    machineConf = {:module, __MODULE__, %{}}

    :ra.start_server(
      :default,
      @ra_cluster_name,
      my_id,
      machineConf,
      [{@ra_cluster_name, @raft_starter}]
    )
  end
end
