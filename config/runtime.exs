import Config

config :processor,
  source: ["github", "trello"]

config :extractor,
  source: ["trello"],
  github_token: System.fetch_env!("GITHUB_TOKEN")

config :loader,
  url: System.fetch_env!("COUCHDB_URL"),
  user_db: System.fetch_env!("COUCHDB_USER"),
  password_db: System.fetch_env!("COUCHDB_PASSWORD"),
  name_db: System.fetch_env!("COUCHDB_NAME")
