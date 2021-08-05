# DharmaServer

## Dependencies

We recommend using [asdf-vm](http://asdf-vm.com/guide/getting-started.html#getting-started) for version management.

1. Elixir 1.12 - https://elixir-lang.org/install.html
2. Erlang/OTP 24 - https://erlang.org/documentation/doc-5.7.4/doc/installation_guide/install.html
3. RabbitMQ - https://www.rabbitmq.com/download.html
4. CouchDB - https://docs.couchdb.org/en/main/install/index.html

## Environment Variables

* RABBIT_URL - RabbitMQ URI
* RABBIT_EXCHANGE - Message exchange
* COUCHDB_URL - CouchDB URL
* COUCHDB_USER - CouchDB username
* COUCHDB_PASSWORD - CouchDB password
* COUCHDB_NAME - CouchDB database name

## Installation

1. Clone the repo
2. cd into the repo
3. `mix deps.get`

Now run the app:

```iex -S mix```

### Other useful commands

- `mix test` --> Run tests

## Project architecture

This application is organized as an [umbrella project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html).