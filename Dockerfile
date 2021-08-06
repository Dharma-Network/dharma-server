###
### Fist Stage - Building the Release
###
FROM hexpm/elixir:1.12.2-erlang-24.0.4-alpine-3.14.0 AS build
WORKDIR /app
ENV MIX_ENV=prod

### Copy source
COPY config ./config
COPY apps ./apps
COPY mix.exs .
COPY mix.lock .
COPY rel ./rel

### Setup system dependencies
RUN apk update && apk add --no-cache build-base

### Setup app dependencies
RUN mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get && \
  mix deps.compile

### Create new release
RUN mix do compile, release

###
### Second Stage - Setup the Runtime Environment
###
FROM alpine:3.14.0 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/dharma_server ./

ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

CMD ["bin/dharma_server", "start"]