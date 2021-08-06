import Config

config :database,
  url_db: System.fetch_env!("COUCHDB_URL"),
  user_db: System.fetch_env!("COUCHDB_USER"),
  password_db: System.fetch_env!("COUCHDB_PASSWORD"),
  name_db: System.fetch_env!("COUCHDB_NAME"),
  jwt_secret: System.fetch_env!("JWT_SECRET")

config :extractor,
  github_token: System.fetch_env!("GITHUB_TOKEN"),
  rabbit_url: System.fetch_env!("RABBIT_URL"),
  rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")

config :loader,
  rabbit_url: System.fetch_env!("RABBIT_URL"),
  rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")

config :processor,
  rabbit_url: System.fetch_env!("RABBIT_URL"),
  rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")
