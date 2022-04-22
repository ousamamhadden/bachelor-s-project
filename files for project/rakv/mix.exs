defmodule KV.MixProject do
  use Mix.Project

  def project do
    [
      app: :kv,
      version: "0.1.0",
      # elixir: "~> 1.12.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        rakv: [
          version: "0.0.1",
          applications: [kv: :permanent],
          cookie: "chocolatebuiscitcookie"
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KVApp, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:ra, github: "rabbitmq/ra", tag: "v1.1.9"},
      {:ra, github: "rabbitmq/ra"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:libcluster, "~> 3.3.1"},
      {:opencensus, "~> 0.9.0"},
      {:opencensus_elixir, "~> 0.4.0", override: true},
      {:opencensus_jaeger, "~> 0.0.1"}
    ]
  end
end
