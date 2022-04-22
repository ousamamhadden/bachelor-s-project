defmodule KVApp do
  use Application

  def start(_, args) do
    # args could be a list of predetermined nodes we want to add to the cluster

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

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: RAKV.Healthcheck,
        options: [port: 8080, transport_options: [num_acceptors: 5]]
      ),
      {Cluster.Supervisor, [topologies, [name: RAKV.ClusterSupervisor]]},
      {Task.Supervisor, name: MyApp.TaskSupervisor},
      Supervisor.child_spec(
        {Task,
         fn ->
           RAMiniGroupCall.start_system(args)
         end},
        id: :worker1
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @spec configure_oc_reporter(nil | binary) ::
          [] | [{:oc_reporter_jaeger, [{:hostname, [any]} | {:service, <<_::104>>}, ...]}]
  def configure_oc_reporter(nil), do: []

  def configure_oc_reporter(hostname),
    do: [
      {:oc_reporter_jaeger,
       [
         hostname: String.to_charlist(hostname),
         service_name: "raft-mini-group-call",
         service_tags: %{"hostname" => elem(:inet.gethostname(), 1)}
       ]}
    ]
end
