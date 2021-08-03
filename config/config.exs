import Config

for app <- [:extractor, :processor, :loader] do
  config app, rabbit_url: System.fetch_env!("RABBIT_URL")
  config app, rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")
end


config :database,
  url_db: System.fetch_env!("COUCHDB_URL"),
  user_db: System.fetch_env!("COUCHDB_USER"),
  password_db: System.fetch_env!("COUCHDB_PASSWORD"),
  name_db: System.fetch_env!("COUCHDB_NAME")
