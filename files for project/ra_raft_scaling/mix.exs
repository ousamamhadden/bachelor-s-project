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
      mod: {KVApp, [:rakv@host1, :rakv@host2, :rakv@host3]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ra, github: "rabbitmq/ra"}
    ]
  end
end
