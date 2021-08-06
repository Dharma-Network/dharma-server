use Mix.Config

config :logger,
  handle_otp_reports: false

config :lager,
  error_logger_redirect: false

import_config "../apps/*/config/config.exs"
