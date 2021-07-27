import Config

config :processor,
  source: ["github", "trello"]

config :extractor,
  source: ["github", "trello"]

config :loader,
  url: System.fetch_env!("COUCHDB_URL"),
  user_db: System.fetch_env!("COUCHDB_USER"),
  password_db: System.fetch_env!("COUCHDB_PASSWORD"),
  name_db: System.fetch_env!("COUCHDB_NAME")
