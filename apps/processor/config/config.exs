import Config

config :processor,
  rabbit_url: System.fetch_env!("RABBIT_URL"),
  rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")
