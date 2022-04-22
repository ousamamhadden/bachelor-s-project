defmodule MiniGroupCall.Application do
  use Application

  import Telemetry.Metrics

  def start(_, _args) do
    prometheus_metrics = TelemetryStatistics.register_all(metrics(), "rakv_reference")

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: MiniGroupCall.Healthcheck,
        options: [port: 8080, transport_options: [num_acceptors: 5]]
      ),
      {:telemetry_poller,
       [
         measurements: [{TelemetryStatistics, :poller, []}],
         period: 10_000
       ]},
      {TelemetryMetricsPrometheus, [metrics: prometheus_metrics]},
      MiniGroupCall.Redix,
      Supervisor.child_spec(
        {Task,
         fn ->
           MiniGroupCall.RedisClient.start()
         end},
        id: :worker1
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      summary("referenceclient.redis.group_call_request.deltatime",
        unit: :nanosecond,
        description:
          "Delta time between sending a get request to the raft cluster and receiving a response, measured on the client"
      ),
      summary("referenceclient.redis.resource_update.deltatime",
        unit: :nanosecond,
        description:
          "Delta time between sending a get request to the raft cluster and receiving a response, measured on the client"
      )
    ]
  end
end
