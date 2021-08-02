import Config

for app <- [:extractor, :processor, :loader] do
  config app, rabbit_url: System.fetch_env!("RABBIT_URL")
  config app, rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")
end

for app <- [:extractor, :loader] do
  config app, url_db: System.fetch_env!("COUCHDB_URL")
  config app, user_db: System.fetch_env!("COUCHDB_USER")
  config app, password_db: System.fetch_env!("COUCHDB_PASSWORD")
  config app, name_db: System.fetch_env!("COUCHDB_NAME")
end
