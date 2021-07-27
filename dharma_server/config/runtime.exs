import Config

config :processor,
       :source,
       ["github", "trello"]

config :extractor,
       :source,
       ["github", "trello"]

config :rabbit,
       :url,
       "amqp://guest:guest@localhost"
