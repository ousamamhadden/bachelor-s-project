defmodule CoffeeMachines.MixProject do
  use Mix.Project

  def project do
    [
      app: :mini_group_call,
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        mini_group_call: [
          version: "0.0.1",
          applications: [mini_group_call: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MiniGroupCall.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:redix, "~> 1.0"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:telemetry, "~> 0.4.1"},
      {:telemetry_metrics, "~> 0.6.0"},
      {:telemetry_metrics_prometheus, "~> 1.0"},
      {:telemetry_metrics_prometheus_core, "~> 1.0"},
      {:telemetry_poller, "~> 0.5.0"},
      {:telemetry_wrappers, "~> 1.0"}
    ]
  end
end
