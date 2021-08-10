use Mix.Config

config :logger, handle_otp_reports: false

import_config "../apps/*/config/config.exs"
