import Config

config :loader,
  rabbit_url: System.fetch_env!("RABBIT_URL"),
  rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")
