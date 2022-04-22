import Config

if config_env() == :prod do
  config :opencensus,
    sampler:
      {:oc_sampler_probability,
       probability: System.get_env("OC_SAMPLING_RATE", "0.0") |> String.to_float()},
    reporters: KVCLientApp.configure_oc_reporter(System.get_env("OC_JAEGER_HOST"))
end
