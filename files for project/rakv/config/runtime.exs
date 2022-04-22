import Config

if config_env() == :prod and Node.self() == :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local" do
  config :opencensus,
    sampler: {:oc_sampler_always, []},
    reporters: KVApp.configure_oc_reporter(System.get_env("OC_JAEGER_HOST"))
end
