import Config

config :database,
  url_db: System.fetch_env!("COUCHDB_URL"),
  user_db: System.fetch_env!("COUCHDB_USER"),
  password_db: System.fetch_env!("COUCHDB_PASSWORD"),
  name_db: System.fetch_env!("COUCHDB_NAME"),
  jwt_secret: System.fetch_env!("JWT_SECRET")
