import Config

config :processor,
       :source,
       ["github", "trello"]

config :extractor,
       :source,
       ["github", "trello"]

config :loader,
  url: "http://127.0.0.1:5984",
  user_db: "admin",
  password_db: "root"

config :rabbit,
       :url,
       "amqp://guest:guest@localhost"
