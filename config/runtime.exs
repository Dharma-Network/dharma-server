import Config

config :processor,
  source: ["github", "trello"]

config :extractor,
  github_token: System.fetch_env!("GITHUB_TOKEN")

