defmodule KVCLientApp do
  use Application

  import Telemetry.Metrics

  def start(_, args) do
    # args could be a list of predetermined nodes we want to add to the cluster
    # IO.puts(Node.self())
    # IO.puts(Node.get_cookie())

    topologies = [
      k8s_kv: [
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNSSRV,
        config: [
          service: "rakv-cluster",
          application_name: "rakv",
          namespace: "ngcp-dev",
          # 10 sec
          polling_interval: 10_000
        ]
      ]
    ]

    prometheus_metrics = TelemetryStatistics.register_all(metrics(), "rakv_client")

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: RAKVClient.Healthcheck,
        options: [port: 8080, transport_options: [num_acceptors: 5]]
      ),
      {Cluster.Supervisor, [topologies, [name: RAKV.ClusterSupervisor]]},
      {:telemetry_poller,
       [
         measurements: [{TelemetryStatistics, :poller, []}],
         period: 10_000
       ]},
      {TelemetryMetricsPrometheus, [metrics: prometheus_metrics]},
      Supervisor.child_spec(
        {Task,
         fn ->
           RakvClient.startt(args)
         end},
        id: :worker1
      ),
      Supervisor.child_spec(
        {Task,
         fn ->
           RakvKiller.startt(args)
         end},
        id: :killer1
      )
      # Supervisor.child_spec(
      #   {Task,
      #    fn ->
      #      KvClient.startt(args)
      #    end},
      #   id: :worker2
      # )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @spec configure_oc_reporter(nil | binary) ::
          [] | [{:oc_reporter_jaeger, [{:hostname, [any]} | {:service, <<_::104>>}, ...]}]
  def configure_oc_reporter(nil), do: []

  def configure_oc_reporter(hostname) do
    res = [
      {:oc_reporter_jaeger,
       [
         hostname: String.to_charlist(hostname),
         service_name: "raft-mini-group-call-client",
         service_tags: %{"hostname" => elem(:inet.gethostname(), 1)}
       ]}
    ]

    IO.puts("#{inspect(res)}")
    res
  end

  defp metrics do
    [
      summary("raftclient.rakv.get.deltatime",
        unit: :nanosecond,
        description:
          "Delta time between sending a get request to the raft cluster and receiving a response, measured on the client"
      ),
      summary("raftclient.rakv.put.deltatime",
        unit: :nanosecond,
        description:
          "Delta time between sending a put request to the raft cluster and receiving a response, measured on the client"
      ),
      summary("raftclient.normalkv.get.deltatime",
        unit: :nanosecond,
        description:
          "Delta time between sending a get request to a normal kv and receiving a response, measured on the client"
      ),
      summary("raftclient.normalkv.put.deltatime",
        unit: :nanosecond,
        description:
          "Delta time between sending a put request to a normal kv  and receiving a response, measured on the client"
      ),
      summary("raftclient.racoffee.start.deltatime",
        unit: :nanosecond,
        description: "time it takes to create the state machine as a raft cluster"
      ),
      summary("raftclient.racoffee.take.deltatime",
        unit: :nanosecond,
        description: "time it takes for a normal operation on the state machine as a raft cluster"
      ),
      summary("raftclient.racoffee.finish.deltatime",
        unit: :nanosecond,
        description: "time it takes to remove the state machine as a raft cluster"
      ),
      summary("raftclient.ra_mini_group_call.group_call_request.deltatime",
        unit: :nanosecond,
        description:
          "time it takes to send and receive a response from the state machine as a raft cluster"
      ),
      summary("raftclient.ra_mini_group_call.resource_update_response.deltatime",
        unit: :nanosecond,
        description:
          "time it takes to send and receive a response from the state machine as a raft cluster"
      ),
      summary("raftclient.ra_mini_group_call.group_call_termination_at_endpoint.deltatime",
        unit: :nanosecond,
        description:
          "time it takes to send and receive a response from the state machine as a raft cluster"
      )
    ]
  end
end
