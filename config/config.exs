import Config

for app <- [:extractor, :processor, :loader] do
  config app, rabbit_url: System.fetch_env!("RABBIT_URL")
  config app, rabbit_exchange: System.fetch_env!("RABBIT_EXCHANGE")
end
