defmodule RakvClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :rakv_client,
      version: "0.1.0",
      # elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        ra_client: [
          version: "0.0.1",
          applications: [rakv_client: :permanent],
          cookie: "chocolatebuiscitcookie"
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {
        KVCLientApp,
        [
          :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"
        ]
        #    ,
        #    :"rakv@rakv-1.rakv-cluster.ngcp-dev.svc.cluster.local",
        #    :"rakv@rakv-2.rakv-cluster.ngcp-dev.svc.cluster.local"
        #  ]
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:libcluster, "~> 3.3.1"},
      {:telemetry, "~> 0.4.1"},
      {:telemetry_metrics, "~> 0.6.0"},
      {:telemetry_metrics_prometheus, "~> 1.0"},
      {:telemetry_metrics_prometheus_core, "~> 1.0"},
      {:telemetry_poller, "~> 0.5.0"},
      {:telemetry_statistics,
       git: "https://dev.azure.com/msi-cie/ngcp/_git/telemetry_statistics", tag: "1.0.0"},
      {:telemetry_wrappers, "~> 1.0"},
      {:opencensus, "~> 0.9.0"},
      {:opencensus_elixir, "~> 0.4.0"},
      {:opencensus_jaeger, "~> 0.0.1"}
    ]
  end
end
